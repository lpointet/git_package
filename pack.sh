#!/bin/bash
function usage() {
    printf "Usage %s: [-h] [-d] <output_file> <old_tag> [new_tag] [git_rep]\n" $(basename $0)
    echo ""
    echo "  -h              : Show this help"
    echo "  -d              : Output a directory instead of an archive"
    echo "  <output_file>   : The name of the generated archive or directory"
    echo "  <old_tag>      : The name of the tag with old version (prod) files"
    echo "  [new_tag]       : The name of the tag with new version (dev) files (default: prod)"
    echo "  [git_rep]       : The git repository file name (default: ./)"
    echo ""
}

#
# paramètres :
# $1 => output      nom de l'archive à créer
# $2 => git_rep     répertoire git
#
function create_tar()
{
    if [ ${1%.*} = $1 ]
    then
        output=$1".tar.gz"
    else
        output=$1
    fi
    git_rep=$2
    option=" --directory ${git_rep} "
    expression=""

    for line in $(cat $input)
    do
        if [ -f ${git_rep}${line} ]
        then
            expression=${expression}" "$line
        fi
    done

    tar $option -czf $output $expression

    if [ -f $output ]
    then
        echo "archive $output created!"
    fi
}
#
# paramètres :
# $1 => input       nom du fichier listant les modifications
# $2 => output      nom du répertoire dans lequel mettre les fichiers
# $3 => git_rep     répertoire git
#
function create_dir()
{
    input=$1
    output=$2
    git_rep=$3

    if [ ! -d $output ]
    then
        mkdir $output
        chmod -R 777 $output
    fi

    for line in $(cat $input)
    do
        if [ -f ${git_rep}${line} ]
        then
            dir=${output}"/"${line%/*}
            if [ ! -d $dir ]
            then
                mkdir -p $dir
            fi
            cp ${git_rep}${line} ${output}"/"${line}
        fi
    done

    echo "directory created!"
}
#
# paramètres :
# $1 => tag_prod    tag git correspondant à l'image de la prod
# $2 => git_rep     répertoire git
# $3 => tag_dev     tag git correspondant au dev
#
# return : ouput    nom du fichier listant les modifications
#
function create_diff_file()
{
    tag_prod=$1
    git_rep=$2

    dir_script=$(pwd)"/"
    output="tmp.txt"

    cd $git_rep
    git diff $tag_dev $tag_prod --name-only > ${dir_script}${output}

    if [ ! $tag_dev = $initial_tag_dev ]
    then
        git checkout $tag_dev --quiet
    fi

    cd $dir_script

    echo $output
}

#
# return : git_rep    racine vers le dépôt git
#
function get_git_rep()
{
    git_rep="$(git rev-parse --git-dir 2>/dev/null)"
    git_rep="${git_rep%/.git}"
    if [ ! $git_rep ]
    then
        git_rep="."
    else
        git_rep="${git_rep%.git}"
        if [ ! $git_rep ]
        then
            git_rep="."
        fi
    fi
    git_rep=$git_rep"/"

    echo $git_rep
}

#
# return : initial_tag_dev    tag/branche/commit sur lequel on se trouve en ce moment
#
function get_current_tag()
{
    if ! initial_tag_dev="$(git symbolic-ref HEAD 2>/dev/null)"
    then
        if ! initial_tag_dev="$(git describe --exact-match HEAD 2>/dev/null)"
        then
            initial_tag_dev="$(cut -c1-7 "$git_rep.git/HEAD")"
        fi
    fi
    initial_tag_dev=${initial_tag_dev##refs/heads/}

    echo $initial_tag_dev
}

# Récupération des options
TAR="TRUE"
while getopts hd option
do
    case "${option}"
    in
        d)  TAR="FALSE";;
        h)  usage
            exit 0;;
    esac
done
shift_arg=`expr $OPTIND - 1`
shift $shift_arg

# Récupération des paramètres
if [ $# = 0 ]
then
    usage
elif [ $# = 1 ]
then
    usage
else
    dir_script=$(pwd)"/"            # On retient le dossier dans lequel on est

    # Récupération du chemin vers le dépôt
    git_rep=$(get_git_rep)

    tag_dev="prod"

    if [ ! $4 = "" ] && [ -d $4 ]            # $4 est le git_rep
    then
        cd $4
        git_rep=$(pwd)"/"
        cd $dir_script

        tag_dev=$3
    elif [ ! $3 = "" ]                      # $3 correspond au git_rep ou tag_dev
    then
        if [ -d $3 ]                        # $3 correspond au git_rep
        then
            cd $3
            git_rep=$(pwd)"/"
            cd $dir_script
        else                                # $3 correspond au tag_dev
            tag_dev=$3
        fi
    fi

    cd $git_rep
    initial_tag_dev=$(get_current_tag)
    cd $dir_script

    input=$(create_diff_file ${2} ${git_rep})

    if [ $TAR = "FALSE" ]
    then
        create_dir $input $1 $git_rep
    else
        create_tar $1 $git_rep
    fi

    if [ -f $input ]
    then
        rm $input
    fi

    if [ ! $tag_dev = $initial_tag_dev ]
    then
        cd $git_rep
        git checkout $initial_tag_dev --quiet
        cd $dir_script
    fi
fi
