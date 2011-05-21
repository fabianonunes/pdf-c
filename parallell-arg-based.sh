#!/bin/bash

	i=$1;

	echo $i;

	# verifying if file is being used	
	lsof $i &> /dev/null;

	if [ $? -eq 0 ]; then
		echo $i "is being used";
		exit;
	fi;


	echo $i "- Building structure..."

	docFolder=${i/.pdf/};
	# rm -rf $docFolder;
	mkdir -p $docFolder;

	imageFolder=$docFolder/images;
	mkdir -p $imageFolder/png/t;

	outlineFolder=$docFolder/outline;
	mkdir -p $outlineFolder;

	textFolder=$docFolder/text;
	simpleTextFolder=$docFolder/text/simple;
	mkdir -p $simpleTextFolder;
	find $textFolder -type f -exec rm {} \;

	indexFolder=$docFolder/index;
	mkdir -p $indexFolder;

	baseName=$(basename $i);
	pdfFile=$docFolder/$baseName;
	mv $i $pdfFile;

	numberOfPages=$(pdfinfo $pdfFile | grep Pages | sed "s/[^0-9]*//gi");

	step=25;

	echo $docFolder "- Generating XML files...";

		parallel -a <(seq 1 $step $numberOfPages) -a <(seq $step $step $((numberOfPages + step))) \
			pdftoxml -noImage -noImageInline -f {1} -l {2} $pdfFile $textFolder/p{1}.xml;

		parallel tidy -utf8 -xml -w 255 -i -c -q -asxml -o {} {} ::: $textFolder/*.xml;

		echo "<DOCUMENT>" > $textFolder/full.xml
		parallel xmlstarlet sel -I -t -c "//PAGE/self::*" {} ::: $textFolder/p*.xml >> $textFolder/full.xml
		echo "</DOCUMENT>" >> $textFolder/full.xml

	# echo $docFolder "- Generating images files...";
	# 	parallel -a <(seq 1 $step $numberOfPages) -a <(seq $step $step $((numberOfPages + step))) \
	# 		/home/fabiano/bin/pdfdraw -r 110 -g -o $imageFolder/png/%d.png $pdfFile {1}-{2} 2> /dev/null;

	# echo $docFolder "- Generating thumbnails..."
	# 	parallel convert -resize x200 -depth 2 {} $imageFolder/png/t/{/} ::: $imageFolder/png/*.png

	
	echo $docFolder "- Merging/Optimizing/Simplifying XML files..."
		parallel xmlstarlet tr {} $textFolder/full.xml ">" $textFolder/{.}.xml ::: *.xslt


	
	# echo $docFolder "- Merging/Optimizing/Simplifying XML files..."
	# 	 java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo optimize-text -i $docFolder

	exit;

	truncate -s 0 java.cmd;
	echo $docFolder "- Merging/Optimizing/Simplifying XML files..."
		echo "-jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo optimize-text -i $docFolder" >> java.cmd;

	echo $docFolder "- Storing document in DB..."
		echo "-jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo store-db -i $docFolder" >> java.cmd;

	ppss -f java.cmd -c 'java  $ITEM ';

	echo $docFolder "- Building index..."
	java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo build-index -i $docFolder -solrHost "http://localhost:8081/reader-index";

	echo " ";

	#echo $docFolder "- Extracting outline..."
	#java -Xmx1024m -jar /home/fabiano/bin/reader-cli.jar -metodo extract-outline -i $docFolder;



