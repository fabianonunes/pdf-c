
i=$1;

echo $i;

# verifying if file is being used	
lsof $i &> /dev/null;

if [ $? -eq 0 ]; then
	echo $i "is being used";
	continue;
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

step=15;

iterations=$(($numberOfPages/$step));

remainder=$(($numberOfPages%$step));

if [ $remainder -ne 0 ]
then
	((iterations++));
fi

pagesToProcess=$((step - 1)); # number of pages to process in each iteration

echo $docFolder "- Generating XML files..."
java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo extract-text -i $docFolder;



echo $docFolder "- Generating images files..."
truncate -s 0 pdfdraw.cmd
for (( c = 0; c < $iterations; c++ )); do

	firstPage=$(($step * $c + 1));
	lastPage=$(($firstPage+$pagesToProcess));
	
	echo "-r 110 -g -o $imageFolder/png/%d.png $pdfFile $firstPage-$lastPage " >> pdfdraw.cmd;

done;
ppss -f pdfdraw.cmd -c '/home/fabiano/bin/pdfdraw $ITEM ';
	

echo $docFolder "- Generating Thumbnails..."
for f in $(find $imageFolder/png -maxdepth 1 -type f -name '*.png'); do
	dir=$(dirname $f);
	convert -resize x200 -depth 2 $f ${f/$dir/$dir\/t};
done;

echo $docFolder "- Merging/Optimizing/Simplifying XML files..."
java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo optimize-text -i $docFolder;

echo $docFolder "- Storing document in DB..."
java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo store-db -i $docFolder;

echo $docFolder "- Building index..."
java -jar /home/fabiano/bin/reader-cli-0.0.3.jar -metodo build-index -i $docFolder -solrHost "http://localhost:8081/reader-index";

echo " ";

#echo $docFolder "- Extracting outline..."
#java -Xmx1024m -jar /home/fabiano/bin/reader-cli.jar -metodo extract-outline -i $docFolder;



