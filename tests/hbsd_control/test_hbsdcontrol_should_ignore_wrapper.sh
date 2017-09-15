#!/bin/sh

test=`mktemp`

cat > $test<<EOF
#!/bin/sh

procstat -v \$\$
EOF

chmod +x $test

hbsdcontrol system aslr disable $test

$test | awk '{print $2" "$3}' > $test.a
$test | awk '{print $2" "$3}' > $test.b

cmp -s $test.a $test.b
ret=$?

if [ $ret == 0 ]
then
	echo "test failed"
	vimdiff $test.a $test.b
	exit 1
else
	echo "test passed"
	rm $test
	rm $test.a $test.b
	exit 0
fi
