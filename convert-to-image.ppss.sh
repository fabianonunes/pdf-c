pdfFile=$1;

	numberOfPages=$(pdfinfo $pdfFile | grep Pages | sed "s/[^0-9]*//gi");
	step=15;
	pagesToProcess=$((step - 1)); # number of pages to process in each iteration
	iterations=$(($numberOfPages/$step));
	remainder=$(($numberOfPages%$step));

	if [ $remainder -ne 0 ]
	then
		((iterations++));
	fi

	

	echo $docFolder "- Generating images files...";
	truncate -s 0 pdfdraw.cmd;
	for (( c = 0; c < $iterations; c++ )); do

		firstPage=$(($step * $c + 1));
		lastPage=$(($firstPage+$pagesToProcess));
		
		echo "-r 110 -g -o %d.png $pdfFile $firstPage-$lastPage" >> pdfdraw.cmd;

	done;

	ppss -f pdfdraw.cmd -c '/home/fabiano/bin/pdfdraw $ITEM ';