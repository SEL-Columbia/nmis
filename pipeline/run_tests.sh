for t in $(ls tests | grep "\.R$"); do
    echo "running $t"
    R CMD BATCH --slave tests/$t /dev/tty
done
