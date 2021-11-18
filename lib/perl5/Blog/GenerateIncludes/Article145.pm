# -----------------------------------------------------------------------------

=head1 NAME

Blog::GenerateIncludes::Article145

=head1 BASE CLASS

L<Blog::Base::Quiq::Program>

=cut

# -----------------------------------------------------------------------------

package Blog::GenerateIncludes::Article145;
use base qw/Blog::Base::Quiq::Program/;

use v5.10;
use strict;
use warnings;

use Blog::Base::Quiq::Path;
use Blog::Base::Quiq::Config;
use Blog::Base::Quiq::Database::Connection;
use Blog::Base::Quiq::Html::Producer;
use Blog::Base::Quiq::Json;
use Blog::Base::Quiq::FileHandle;
use Blog::Base::Quiq::PlotlyJs::XY::Diagram;
use Blog::Base::Quiq::Url;
use Blog::Base::Quiq::PlotlyJs::TimeSeries;
use Blog::Base::Quiq::PlotlyJs::XY::DiagramGroup;
use Blog::Base::Quiq::Sdoc::Producer;
use Blog::Base::Quiq::Html::Component;
use Blog::Base::Quiq::Html::Widget::SelectMenu;
use Blog::Base::Quiq::JavaScript;
use Blog::Base::Quiq::Html::Widget::CheckBox;
use Blog::Base::Quiq::Html::Widget::Button;
use Encode ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Objektmethoden

=head3 main() - Hauptprogramm

=head4 Synopsis

  $prg->main;

=cut

# -----------------------------------------------------------------------------

sub main {
    my $self = shift;

    # Globale Information
    my $workDir = $FindBin::Bin;

    # Allgemein genutzte  Objekte
    my $p = Blog::Base::Quiq::Path->new;

    # Optionen und Argumente

    my ($argA,$opt) = $self->parameters(0,0,0,
        -mtime => 0,
        -help => 0,
    );

    # Operation ausführen

    if ($opt->mtime) {
        # Liefere nur den letzten Änderungszeitpunkt des Programms
        say $self->mtime;
        return;
    }

    # Dateien generieren

    # * Datenbankverbindung aufbauen

    my $conf = Blog::Base::Quiq::Config->new('~/etc/opt/tsplot/devel.conf');
    my $udl = $conf->get('UdlTseries');
    my $db = Blog::Base::Quiq::Database::Connection->new($udl,-utf8=>1);

    # * Daten selektieren

    # ** Zeitbereich

    my $begin = '2009-02-19 00:00:00';
    my $end = '2009-02-24 00:00:00';

    # ** Station

    my $sta = $db->lookup('station',
        sta_name => 'LandStation_GKSS1',
    );

    # ** Parameter

    my @parameters = (
        'AirTemperature',
        'WindSpeed',
        # 'WindDirection',
        'AirPressure',
        'RelativeHumidity',
        'GlobalRadiation',
    );

    # *** Metainformation von der Datenbank selektieren

    my $parT = $db->select(qq~
        SELECT
            par_id
            , par_name
            , par_unit
            , par_ymin
            , par_ymax
            , par_color
            , MIN(val_time) AS par_time_min
            , MAX(val_time) AS par_time_max
            , COALESCE(MIN(val_value), par_ymin, 0) AS par_value_min
            , COALESCE(MAX(val_value), par_ymax, 1) AS par_value_max
        FROM
            parameter AS par
            LEFT JOIN value AS val
                ON par_id = val_parameter_id
                    AND val_time >= '__BEGIN__'
                    AND val_time < '__END__'
        WHERE
            par_station_id = __STA_ID__
            AND par_name IN (__PARAMETERS__)
        GROUP BY
            par_id
            , par_name
            , par_unit
            , par_ymin
            , par_ymax
            , par_color
        ~,
        -placeholders =>
            __STA_ID__ => $sta->sta_id,
            __PARAMETERS__ => !@parameters? "''":
                join(', ',map {"'$_'"} @parameters),
            __BEGIN__ => $begin,
            __END__ => $end,
    );
    $parT->normalizeNumber('par_ymin','par_ymax','par_value_min',
        'par_value_max');
    my %parI = $parT->index('par_name');

print $parT->asTable;

    # *** Parameter-Objekte instantiieren

    my $h = Blog::Base::Quiq::Html::Producer->new;
    my $j = Blog::Base::Quiq::Json->new;

    my (@par,$obj);
    for my $parameter (@parameters) {
        my $par = $parI{$parameter} // $self->throw;

        # Daten in Datei sichern, zum Hochladen auf s31tz.de

        my $valT;
        if (1) {
            $valT = $db->select(
                -select =>
                    'val_time',
                    "EXTRACT(EPOCH FROM val_time) * 1000 AS val_time_js",
                    'val_value',
                    "'#' || qua_color AS qua_color",
                -from => 'tseries.value JOIN tseries.quality'.
                    ' ON val_quality = qua_value',
                -where,
                   val_parameter_id => $par->par_id,
                   "val_time >= '$begin'",
                   "val_time <= '$end'",
                -orderBy => 'val_time',
            );
            $valT->normalizeNumber('val_value');

            my $fh = Blog::Base::Quiq::FileHandle->new('>',"~/tmp/$parameter.dat");
            for my $row ($valT->rows) {
                $fh->print(sprintf "%s\t%s\t%s\n",$row->val_time,
                    $row->val_value,$row->qua_color);
            }
            $fh->close;
        }

        my $par_name = $par->par_name;
        my $par_value_min = $par->par_value_min;
        my $par_value_max = $par->par_value_max;
        if ($par_value_min eq '') {
            $par_value_min = 0;
            $par_value_max = 1;
        }
printf "%s-%s\n",$par_value_min,$par_value_max;
        push @par,Blog::Base::Quiq::PlotlyJs::XY::Diagram->new(
            title => $par_name,
            yTitle => Encode::decode('utf-8',$par->par_unit), # ????
            color => '#'.$par->par_color,
            yTitleColor => '#'.$par->par_color,
            x => scalar($valT->values('val_time')),
            xMin => $begin, # $par->par_time_min,
            xMax => $end, # $par->par_time_max,
            y => scalar($valT->values('val_value')),
            yMin => $par_value_min,
            yMax => $par_value_max,
            #url => 'http://s31tz.de/timeseries?'.Blog::Base::Quiq::Url->queryEncode(
            #    name => $par->par_name,
            #),
            z => scalar($valT->values('qua_color')),
            zName => 'Quality',
            #html => $h->tag('div',
            #   style => 'position: absolute; top: 0.3em; right: 0.5em',
            #   'Menu'
            #),
        );

#        #  JavaScript-Struktur erzeugen
#
#        $par = $par[-1];
#        if ($obj) {
#            $obj .= ',';
#        }
#        $obj .= $j->o(
#            name => $par->name,
#            unit => $par->unit,
#            color => $par->color,
#            x => $par->x,
#            y => $par->y,
#            yMin => $par->yMin,
#            yMax => $par->yMax,
#        );
    }
#   $obj = "[$obj]";

#    # Diagramm für ersten Parameter erzeugen
#
#    my $par = $par[0];
#    my $plt = Blog::Base::Quiq::PlotlyJs::TimeSeries->new(
#        title => $par->name,
#        yTitle => $par->unit,
#        color => $par->color,
#        height =>  300,
#        yMin => $par->yMin,
#        yMax => $par->yMax,
#        xMin => $par->xMin,
#        xMax =>  $par->xMax,
#        # FIXME: nachträglich laden
#        x => $par->x,
#        y => $par->y,
#    );

    # * Sdoc Format-Block erzeugen

    my $dig = Blog::Base::Quiq::PlotlyJs::XY::DiagramGroup->new(
        # type => 'scattergl',
        # fontSize => 18,
        height => 280,
        diagrams => \@par,
        strict => 0, # auf dem Blog wollen wir kein alert()
        # xAxisType => 'linear',
        # xTitle => 'Time',
    );

    my $s = Blog::Base::Quiq::Sdoc::Producer->new;
    my $sdoc = $s->format(
        HTML => $h->cat(
#            Blog::Base::Quiq::Html::Component->fragment($h,
#                html => $plt->html($h),
#                ready => $plt->js,
#            ),
#            $h->tag('div',style=>'margin-top: 0.6em','-',
#                'Parameter: '.Blog::Base::Quiq::Html::Widget::SelectMenu->html($h,
#                    id => 'parameter',
#                    options => [0 .. 4],
#                    texts => \@parameters,
#                    onChange => sprintf(q~
#                        var i = $('#parameter').val();
#                        var p = %s[i];
#                        Plotly.relayout('plot',{
#                            'title.text': p.name,
#                            'title.font.color': p.color,
#                            'yaxis.title.text': p.unit,
#                            'yaxis.title.font.color': p.color,
#                            'yaxis.range': [p.yMin,p.yMax],
#                        });
#                        // Plotly.restyle('plot',{
#                        //    'x': [p.x],
#                        //    'y': [p.y],
#                        // },0);
#                        Plotly.deleteTraces('plot',0);
#                        Plotly.addTraces('plot',{
#                             'type': 'scatter',
#                             'mode': $('#shape').val(),
#                             'fill': 'tozeroy',
#                             'fillcolor': '#e0e0e0',
#                             'line': {
#                                 'width': 1,
#                                 'color': p.color,
#                                 'shape': $('#shape').val(),
#                             },
#                             marker: {
#                                 size: 3,
#                                 color: p.color,
#                                 symbol: 'circle',
#                             },
#                             'x': p.x,
#                             'y': p.y,
#                        });
#                        var shape = $('#shape').val();
#                        if (shape == 'Splines') {
#                            Plotly.restyle('plot',{
#                                'mode': 'lines',
#                                'line.shape': 'spline',
#                            });
#                        }
#                        else if (shape == 'Markers') {
#                            Plotly.restyle('plot',{
#                                'mode': 'markers',
#                            });
#                        }
#                        else { // Lines
#                            Plotly.restyle('plot',{
#                                'mode': 'lines',
#                                'line.shape': 'linear',
#                            });
#                        }
#                    ~,$obj),
#                    title => 'Parameter, dessen Daten dargestellt werden',
#                ),
#    #            ' Color: '.Blog::Base::Quiq::Html::Widget::SelectMenu->html($h,
#    #                id => 'color',
#    #                optionPairs => [
#    #                    '#009900' => 'Green',
#    #                    '#0000cc' => 'Blue',
#    #                    '#ff0000' => 'Red',
#    #                    '#ffff00' => 'Yellow',
#    #                ],
#    #                onChange => Blog::Base::Quiq::JavaScript->line(q~
#    #                    var color = $('#color').val();
#    #                    Plotly.restyle('plot',{
#    #                        'line.color': color,
#    #                        'marker.color': color,
#    #                    });
#    #                    Plotly.relayout('plot',{
#    #                        'title.font.color': color,
#    #                        'yaxis.title.font.color': color,
#    #                    });
#    #                ~),
#    #                title => 'Farbe der Kurve, des Titels und des Y-Titels',
#    #            ),
#                ' | Shape: '.Blog::Base::Quiq::Html::Widget::SelectMenu->html($h,
#                    id => 'shape',
#                    options => [
#                        'Lines',
#                        'Splines',
#                        'Markers',
#                    ],
#                    onChange => Blog::Base::Quiq::JavaScript->line(q~
#                        var shape = $('#shape').val();
#                        if (shape == 'Splines') {
#                            Plotly.restyle('plot',{
#                                'mode': 'lines',
#                                'line.shape': 'spline',
#                            });
#                        }
#                        else if (shape == 'Markers') {
#                            Plotly.restyle('plot',{
#                                'mode': 'markers',
#                            });
#                        }
#                        else { // Lines
#                            Plotly.restyle('plot',{
#                                'mode': 'lines',
#                                'line.shape': 'linear',
#                            });
#                        }
#                    ~),
#                    title => 'Verbinde die Datenpunkte durch eine'.
#                        '  gerade Line, per Spline oder markiere sie',
#                ),
#                ' | Rangeslider:'.Blog::Base::Quiq::Html::Widget::CheckBox->html($h,
#                    option => 1,
#                    value => 1,
#                    style => 'vertical-align: middle',
#                    onClick => Blog::Base::Quiq::JavaScript->line(q~
#                        var originalHeight = $('#plot').attr('originalHeight');
#                        var originalBottomMargin =
#                            $('#plot').attr('originalBottomMargin');
#                        var visible = true;
#                        var height = originalHeight;
#                        var margin = originalBottomMargin;
#                        var y = 1-(15/height); // 0.965;
#                        var fixedRange = false;
#                        if (!this.checked) {
#                            visible = false;
#                            var marginDelta = margin-55;
#                            height -= marginDelta;
#                            margin -= marginDelta;
#                            y = 1-(originalHeight*(1-y)/height);
#                            fixedRange = true;
#                        }
#                        Plotly.relayout('plot',{
#                            'xaxis.rangeslider.visible': visible,
#                            'xaxis.fixedrange': fixedRange,
#                            'height': height,
#                            'margin.b': margin,
#                            'title.y': y,
#                        });
#                        $('#plot').height(height);
#                    ~),
#                    title => 'Zeige Rangeslider an',
#                ),
#                ' | '.Blog::Base::Quiq::Html::Widget::Button->html($h,
#                    content => 'Download as PNG',
#                    onClick => q~
#                        // alert($('#plot').width());
#                        Plotly.downloadImage('plot',{
#                            format: 'png',
#                            width: $('#plot').width(),
#                            height: $('#plot').height(),
#                            filename: 'windspeed',
#                        });
#                    ~,
#                    title => 'Lade die aktuelle Plot-Grafik als PNG herunter',
#                ),
#            ),
            $dig->html($h),
        ),
        LaTeX => '',
    );

# print Encode::encode('utf-8',$sdoc);

    $p->write("$workDir/plots.sinc",$sdoc,-encode=>'utf-8');

    return;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
