# Main Function
main() {
    dest_path=$1
    if [ -z $dest_path ]; then
        dest_path="."
    fi

    root_path=$(
        cd $dest_path
        pwd
    )
    cd $root_path
    for dir in $(ls $root_path); do
        if [ -f $dir ]; then
            echo "$dir is a file"
            continue
        fi

        if [ ! -d $dir/.git ]; then
            echo "$dir is not git project"
            continue
        fi

        cd $dir

        current_branch=$(git branch | grep '^\*' | cut -d' ' -f2)
        echo "curent branch is $current_branch"
        is_master=false
        if [ "$current_branch" == "master" ]; then
            is_master=true
        fi
        did_stashed=false

        echo "========================================================"
        git remote -v
        echo

        echo "--------------------------------------------------------"
        echo "* git stash"
        echo
        stash_count_1=$(git stash list | wc -l)
        git add .
        git stash
        stash_count_2=$(git stash list | wc -l)
        if [ $stash_count_1 != $stash_count_2 ]; then
            did_stashed=true
        fi
        echo

        if ! $is_master; then
            echo "--------------------------------------------------------"
            echo "* checkout master branch"
            echo
            git checkout master
            echo

        fi

        echo "--------------------------------------------------------"
        echo "* git pull"
        echo
        git pull
        echo

        echo "--------------------------------------------------------"
        echo "* prune remote branch"
        echo
        git remote prune origin
        echo

        if ! $is_master; then
            echo "--------------------------------------------------------"
            echo "* recover $current_branch"
            echo
            git checkout $current_branch
            echo
        fi

        if $did_stashed; then
            echo "--------------------------------------------------------"
            echo "* recover commits"
            echo
            git stash pop
            git reset
            echo
        fi

        echo "========================================================"
        echo

        cd ..
    done
}

## Execute Main Function
main $*
