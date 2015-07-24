package Blog::Base::DbmsApi::Dbi::Database;
BEGIN {
    $INC{'Blog::Base/DbmsApi/Dbi/Database.pm'} ||= __FILE__;
}
use base qw/Blog::Base::DbmsApi::Database/;

use strict;
use warnings;
use utf8;

use DBI;
use Blog::Base::DbmsApi::Dbi::Cursor;
use Blog::Base::Misc;
use Blog::Base::Hash;
use Blog::Base::Array;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::DbmsApi::Dbi::Database - Datenbankverbindung über den DBI-Layer

=head1 BASE CLASS

Blog::Base::DbmsApi::Database

=head1 ATTRIBUTES

=over 4

=item dbh => $dbh

DBI Database Handle.

=item dbms => $dbms

Name des DBMS, für DBMS-spezifische Fallunterscheidungen.

=back

=head1 DESCRIPTION

Ein Objekt der Klasse Blog::Base::DbmsApi::Dbi::Database repräsentiert eine
Verbindung zu einer Relationalen Datenbank über den DBI-Layer.

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new()

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $udlObj = shift;
    # @_: @opt

    my (undef,$dbms,$db,$user,$passw,$host,$port,$opts) = $udlObj->elements;

    # Optionen

    my $handle = undef;
    my $utf8 = 0;

    Blog::Base::Misc->argExtract(\@_,
        -handle=>\$handle,
        -utf8=>\$utf8,
    );

    my ($dsn,$name);
    if ($dbms eq 'mysql') {
        $dsn = "DBI:mysql:database=$db";
        if ($host) {
            $dsn .= ";host=$host";
        }
        if ($port) {
            $dsn .= ";port=$port";
        }
    }
    elsif ($dbms eq 'oracle') {
        if ($host) {
            # Connect ohne tnsnames.ora, siehe DBD::Oracle,
            # wird konkret benötigt für FINO
            # FIXME: Port?
            $dsn = "DBI:Oracle:host=$host;sid=$db";
        }
        else {
            $dsn = "DBI:Oracle:$db";
        }
    }
    elsif ($dbms eq 'postgresql') {
        $dsn = "DBI:Pg:dbname=$db";
        if ($host) {
            $dsn .= ";host=$host";
        }
        if ($port) {
            $dsn .= ";port=$port";
        }
    }
    elsif ($dbms eq 'sqlite') {
        $dsn = "DBI:SQLite:dbname=$db";
    }
    else {
        $class->throw(q{DBMSAPI-00001: Nicht-unterstütztes DBMS},Dbms=>$dbms);
    }

    my $errSub = sub {
        my $msg = shift;
        my $h = shift;

        # Bei PostgreSQL liefern $h->err und $h->errstr
        # bei einem fehlgeschlagenen Verbindungsaufbau undef.

        my $err = $h->err || 0;
        my $errstr = $h->errstr || 'Unknown Error';

        my ($stmt,$pos);
        $stmt = $1 if $msg =~ /\[for statement [`'"]+(.+)[`'"]+\]/si;

        my $stdErr = 0;
        if ($dbms eq 'mysql') {
            if ($err == 1062) {
                $stdErr = 4;
            }
            $msg = sprintf('MYSQL-%05d: %s',$err,$errstr);
        }
        elsif ($dbms eq 'oracle') {
            if ($err == 1) {
                $stdErr = 4;
            }
            $pos = $1 if $errstr =~ /at char (\d+)/;
            $errstr =~ s|\s*\(DBD.*||s;
            $msg = $errstr;
        }
        elsif ($dbms eq 'postgresql') {
            if ($errstr =~ /unique.constraint/i) {
                $stdErr = 4;
            }

            # MEMO: Die Positionsangabe ist (immer?) um 45
            # Zeichen zu groß. Man kann im Server-Log sehen,
            # dass den Statements dort entsprechend viel
            # Whitespace vorangestellt ist.

            $pos = $1-45 if $msg =~ /at character (\d+)/si;

            # FIXME: $err ist immer 7. Warum?
            $msg = sprintf('PGSQL-%05d: %s',$err,$errstr);
        }
        elsif ($dbms eq 'sqlite') {
            if ($err == 19) {
                $stdErr = 4;
            }
            #elsif ($err == 1) {
            #    # Fehler unterdrücken:
            #    return;
            #}

            $errstr =~ s| at.*?$||;  # " at FILE.c line N" entf.
            $errstr =~ s|\(\d+\)$||; # "(1)" entf.
            $msg = sprintf('SQLITE-%05d: %s',$err,$errstr);
        }

        if ($stmt) {
            substr($stmt,$pos,0) = '<*>' if $pos;
            $stmt =~ s|^\s+||;
            $stmt =~ s|\s+$||;
        }

        if ($stdErr) {
            my $stdMsg;
            if ($stdErr == 4) {
                $stdMsg = "DB-00004: Unique Constraint verletzt";
            }
            $class->throw($stdMsg,Internal=>$msg,Command=>$stmt);
        }
        else {
            $class->throw($msg,Command=>$stmt);
        }
    };

    my ($dbh,$strict);
    if ($handle) {
        $dbh = $handle; # bereits aufgebaute Db-Verbindung
        $strict = 0;
    }
    else {
        $dbh = DBI->connect($dsn,$user,$passw,{
            HandleError=>$errSub,
            RaiseError=>1,
            ShowErrorStatement=>1,
            AutoCommit=>0,
            Warn=>0,
        });
        $strict = 1;
    }

    if (!$handle) {
        if ($dbms eq 'oracle') {
            $dbh->{'LongReadLen'} = 1024*1024; # 1MB
            if ($utf8) {
                $dbh->{'ora_charset'} = 'AL32UTF8';
            }
        }
        elsif ($dbms eq 'postgresql') {
            if ($utf8) {
                $dbh->{'pg_enable_utf8'} = 1;
                # $dbh->do('SET client_encoding TO utf8');
            }
            else {
                $dbh->{'pg_enable_utf8'} = 0;
                # scheinbar nötig
                $dbh->do('SET client_encoding TO latin1');
            }
            # keine \-Escapes in String-Literalen zulassen
            $dbh->do("SET standard_conforming_strings = ON");
        }
        elsif ($dbms eq 'sqlite') {
            if ($utf8) {
                # $dbh->{'unicode'} = 1;
                $dbh->{'sqlite_unicode'} = 1;
            }
        }
        elsif ($dbms eq 'mysql') {
            if ($utf8) {
                $dbh->{'mysql_enable_utf8'} = 1;
                $dbh->do('SET NAMES utf8');
            }
            # Schalte in den "Strict SQL Mode"
            $dbh->do("SET sql_mode = 'STRICT_TRANS_TABLES'");
        }
        else {
            $class->throw('Not implemented');
        }
    }
    my $hash = Blog::Base::Hash->new(
        dbh=>$dbh,
        dbms=>$dbms,
        # Strict-Umschaltung
        strict=>$strict,
        errSub=>$errSub,
        HandleError=>undef,
        RaiseError=>undef,
        ShowErrorStatement=>undef,
        AutoCommit=>undef,
        Warn=>undef,
    );

    return $class->bless($hash);
}

# -----------------------------------------------------------------------------

=head3 destroy()

=cut

# -----------------------------------------------------------------------------

sub destroy {
    #my ($self) = @_;

    #if (my $dbh = $self->get('dbh')) {
    #    $dbh->disconnect;
    #}
    $_[0] = undef;

    return;
}

#sub DESTROY {
#    my $self = shift;
#    if (my $dbh = $self->get('dbh')) {
#        $dbh->disconnect;
#    }
#    return;
#}

sub DESTROY {
    my $self = shift;
    if ($self->{'dbms'} eq 'sqlite') {
        # $self->sql('BEGIN');
    }
}

# -----------------------------------------------------------------------------

=head2 Sonstige Methoden

=head3 strict() - Schalte Datenbankverbindung in den Strict-Modus

=head4 Synopsis

    $bool = $db->strict;
    $bool = $db->strict($bool);

=cut

# -----------------------------------------------------------------------------

sub strict {
    my $self = shift;
    # @_: $bool

    if (@_) {
        my $bool = shift;

        my $strict = $self->{'strict'};
        if ($bool xor $strict) {
            my $dbh = $self->{'dbh'};
            if ($bool) {
                # Aktuelle $dbh-Einstellungen sichern

                $self->{'HandleError'} = $dbh->{'HandleError'};
                $self->{'RaiseError'} = $dbh->{'RaiseError'};
                $self->{'ShowErrorStatement'} = $dbh->{'ShowErrorStatement'};
                $self->{'AutoCommit'} = $dbh->{'AutoCommit'};
                $self->{'Warn'} = $dbh->{'Warn'};

                # Strict-Mode aktivieren

                $dbh->{'HandleError'} = $self->{'errSub'};
                $dbh->{'RaiseError'} = 1;
                $dbh->{'ShowErrorStatement'} = 1;
                $dbh->{'AutoCommit'} = 0;
                $dbh->{'Warn'} = 0;

                $self->{'strict'} = 1;
            }
            else {
                # Ursprüngliche $dbh-Einstellungen wiederherstellen

                $dbh->{'HandleError'} = $self->{'HandleError'};
                $dbh->{'RaiseError'} = $self->{'RaiseError'};
                $dbh->{'ShowErrorStatement'} = $self->{'ShowErrorStatement'};
                $dbh->{'AutoCommit'} = $self->{'AutoCommit'};
                $dbh->{'Warn'} = $self->{'Warn'};

                $self->{'strict'} = 0;
            }
        }
    }

    return $self->{'strict'};
}

# -----------------------------------------------------------------------------

=head3 maxBlobSize() - Liefere/Setze maximale Größe eines BLOB/TEXT-Werts (Oracle)

=head4 Synopsis

    $n = $db->maxBlobSize;
    $n = $db->maxBlobSize($n);

=head4 Description

Liefere/Setze die maximale Größe eines BLOB/TEXT-Werts auf $n Bytes.
Defaulteinstellung ist 1024*1024 Bytes (1MB).

Dieser Wert ist nur für Oracle relevant und wird bei der Selektion
von BLOB/TEXT-Kolumnen benötigt. Ist der Wert einer BLOB/TEXT-Kolumne
größer als die angegebene Anzahl an Bytes wird eine Exception
ausgelöst.

Bei anderen DBMSen als Oracle hat das Setzen keinen Effekt und der
Returnwert ist immer 0.

=cut

# -----------------------------------------------------------------------------

sub maxBlobSize {
    my $self = shift;
    # @_: $n

    if ($self->{'dbms'} ne 'oracle') {
        return 0;
    }

    if (@_) {
        $self->{'dbh'}->{'LongReadLen'} = shift;
    }

    return $self->{'dbh'}->{'LongReadLen'};
}

# -----------------------------------------------------------------------------

=head3 sql()

=cut

# -----------------------------------------------------------------------------

sub sql {
    my $self = shift;
    my $stmt = shift;
    my $forceExec = shift;

    my ($dbh,$dbms) = $self->get(qw/dbh dbms/);

    my $sth = undef;
    my $bindVars = 0;
    my $titles = [];
    my $hits = 0;
    my $id = 0;

    if (!$stmt) {
        # Leeres Statement: nichts tun und Pseudocursor liefern
    }
    elsif ($dbms eq 'postgresql' && $stmt =~ /^\s*(COMMIT|ROLLBACK)\s*$/i) {

        # DBD::Pg hat Methoden für COMMIT und ROLLBACK. Diese *müssen*
        # benutzt werden. Wir rufen sie hier auf und liefern einen
        # Pseudocursor.

        if ($stmt =~ /COMMIT/i) { $dbh->commit }
        else { $dbh->rollback }
    }
    else {
        $sth = $dbh->prepare($stmt);

        $bindVars = $sth->{'NUM_OF_PARAMS'}; # Anzahl Bind-Variablen

        if (!$bindVars || $forceExec) {
            $sth->execute;

            # Id. 0, wenn nicht verfügbar. Diese Abfrage muss unmittelbar
            # nach dem execute() erfolgen!

            if ($dbms eq 'mysql') {
                $id = $dbh->{'mysql_insertid'};
            }
            elsif ($dbms eq 'sqlite') {
                $id = $dbh->func('last_insert_rowid');
            }

            # Hits. -1, wenn unbekannt oder nicht verfügbar. Wir mappen auf 0.

            $hits = $sth->rows; 
            $hits = 0 if $hits < 0;
        }
        if ($sth->{'NUM_OF_FIELDS'}) {
            # Anmerkungen:
            # * Bei SELECT mit Bind-Variablen sind die
            #   Kolumnentitel erst nach dem Aufruf von bind() verfügbar.
            # * DBD::SQLite liefert undef, daher initialisieren wir
            #   hier als Fallback im Zweifel auf ein leeres Array.
            # * In exotischen Fällen können Kolumnennamen nicht-\w-Zeichen
            #   enthalten. Daher konvertieren wir nicht nur in Kleinschreibung,
            #   sondern nicht-\w-Zeichen nach '_'.

            # alt:
            $titles = Blog::Base::Array->bless($sth->{'NAME_lc'} || []);

            # neu:
            #$titles = Blog::Base::Array->new;
            #my $names = $sth->{'NAME_lc'} || [];
            #for my $name (@$names) {
            #    $name =~ s/\W/_/g;
            #    push @$titles,$name;
            #}

            $hits = 0; # es wurden noch keine Datensätze gelesen
        }
    }

    return Blog::Base::DbmsApi::Dbi::Cursor->new(
        sth=>$sth,
        bindVars=>$bindVars,
        db=>$self,
        titles=>$titles,
        hits=>$hits,
        id=>$id,
    );
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, http://fseitz.de/

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
