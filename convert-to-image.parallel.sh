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
	parallel -a <(seq 1 $step $numberOfPages) -a <(seq $step $step $((numberOfPages + step))) \
		/home/fabiano/bin/pdfdraw -r 110 -g -o %d.png $pdfFile {1}-{2};
