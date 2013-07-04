#!/bin/sh


### Czcionka podpisu pod zdjeciem
FONT_SOURCE="/home/ks/.fonts/PF_Temptesta_Seven/PFTempestaSevenExtended_PL.ttf"
### Czcionka zrodla
FONT_DESC="/usr/share/fonts/type1/gsfonts/z003034l.pfb"


FONT_SOURCE_SIZE=8
FONT_DESC_SIZE=22

BORDER_SIZE=10

### Predefiniowany styl ramki ('white', 'black', :] )
BORDER_THEME='white'

### Jakos plikow JPEG
QUALITY_JPEG=90

### Maksymalna rozdzielczosc nowego pliku + ramka
MAX_WIDTH=800
MAX_HEIGHT=800

# Dodawac prefiks "źródło"  do zrodla z lewej strony?
# yes - "źródło: "
# no  - brak
# dowolny
SOURCE_PREFIX='yes'
### NIZEJ NIE MA NIC DO KONFIGUROWANIA ##############################################
#####################################################################################

if [ -z "$1" ] || [ ! -r $1 ] ; then
    echo "Usage: border.sh <fielename>"
    exit 1
fi

IN_FN=$1
OUT_FN=$(dirname ${IN_FN})/ramka_$(basename ${IN_FN})
INNER_FN=$(dirname ${IN_FN})/tmp_$(basename ${IN_FN}).png

if [ $SOURCE_PREFIX = 'yes' ] ; then
    SOURCE_PRFX="źródło: "
elif [ $SOURCE_PREFIX = 'no' ] ; then
    SOURCE_PRFX=''
else
    SOURCE_PRFX=${SOURCE_PREFIX}
fi


if [ $BORDER_THEME = 'black' ] ; then
    COLOR_BORDER_OUTER="#000000"
    COLOR_BORDER_INNER="#ffffff"
    COLOR_FONT_SOURCE="#a4a4a4"
    COLOR_FONT_DESC="#ffffff"
elif [ $BORDER_THEME = 'white' ] ; then
    COLOR_BORDER_OUTER="#ffffff"
    COLOR_BORDER_INNER="#000000"
    COLOR_FONT_SOURCE="#4c4c4c"
    COLOR_FONT_DESC="#000000"
else
    COLOR_BORDER_OUTER="#00ff00"
    COLOR_BORDER_INNER="#ff00ff"
    COLOR_FONT_SOURCE="#4c4c4c"
    COLOR_FONT_DESC="#ff00ff"
fi


SOURCE_TXT=$(exiftool -s -s -s -Source ${IN_FN})
SOURCE=${SOURCE_PRFX}${SOURCE_TXT}

DPI_X=$(identify -format "%[resolution.x]" ${IN_FN})
DPI_Y=$(identify -format "%[resolution.y]" ${IN_FN})
DPI_UNITS=PixelsPerInch

CHANNELS=$(identify -format "%[channels]" ${IN_FN})

DESTINATION=$(exiftool -s -s -s -Destination ${IN_FN})
DESCRIPTION=$(exiftool -s -s -s -Title ${IN_FN})


convert ${IN_FN} -density ${DPI_X}x${DPI_Y} -resize ${MAX_WIDTH}x${MAX_HEIGHT}\> -bordercolor ${COLOR_BORDER_INNER} -border 1x1 -set colorspace sRGB PNG32:${INNER_FN}

### Jezeli Grayscale to konwersja do RGB
#if [ "${CHANNELS}" = 'gray' ] ; then
    #echo "Gray to RGB"
    #convert ${IN_FN} -colorspace RGB -type TrueColor PNG32:${INNER_FN}
#fi

WIDTH=$(identify -format "%[fx:w]" ${INNER_FN})

### Jezeli jakis opis zrodlowy istnieje to dodajemy miejsce dla niego
if [ ! -z "${DESTINATION}" ] || [ ! -z "${SOURCE_TXT}" ] ; then
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -gravity south -background ${COLOR_BORDER_OUTER} -splice 0x12 PNG32:${INNER_FN}
fi

### Jezeli przeznaczenie istnieje to je dodajemy do zdjecia
if [ ! -z "${DESTINATION}" ] ; then
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -gravity SouthWest -font ${FONT_SOURCE} -pointsize ${FONT_SOURCE_SIZE} -fill ${COLOR_FONT_SOURCE} -annotate +1+0 "${DESTINATION}" PNG32:${INNER_FN}
fi

### Jezeli zrodlo istnieje to je dodajemy do zdjecia
if [ ! -z "${SOURCE_TXT}" ] ; then
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -gravity SouthEast -font ${FONT_SOURCE} -pointsize ${FONT_SOURCE_SIZE} -fill ${COLOR_FONT_SOURCE} -annotate +1+0 "${SOURCE}" PNG32:${INNER_FN}
fi

### Jezeli opis istnieje to go dodajemy do zdjecia
if [ ! -z "${DESCRIPTION}" ] ; then
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -gravity SouthWest -background ${COLOR_BORDER_OUTER} -font ${FONT_DESC} -pointsize ${FONT_DESC_SIZE} -fill ${COLOR_FONT_DESC} -size ${WIDTH}x caption:"${DESCRIPTION}" -append PNG32:${INNER_FN}
fi

### Jezeli byl Grayscale to do tego wracamy
if [ "${CHANNELS}" = 'gray' ] ; then
    # echo "RGB to Gray"
    # convert ${INNER_FN} -set colorspace Gray ${INNER_FN}
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -units ${DPI_UNITS} -bordercolor ${COLOR_BORDER_OUTER} -border ${BORDER_SIZE}x${BORDER_SIZE} -set colorspace Gray -quality ${QUALITY_JPEG}% ${OUT_FN}
else
    convert ${INNER_FN} -density ${DPI_X}x${DPI_Y} -units ${DPI_UNITS} -bordercolor ${COLOR_BORDER_OUTER} -border ${BORDER_SIZE}x${BORDER_SIZE} -quality ${QUALITY_JPEG}% ${OUT_FN}    
fi

### Usuwamy plik tymczasowy
if [ -r ${INNER_FN} ] ; then
    rm ${INNER_FN}
fi
