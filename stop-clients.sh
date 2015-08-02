for i in {1..16};
do
    tmux kill-window -t "client-$i"
done
