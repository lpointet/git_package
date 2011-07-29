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
#
function create_tar()
{
    local output=""
    if [ ${1%.*} = $1 ]
    then
        output=$1".tar.gz"
    else
        output=$1
    fi
    option=" --directory ${git_rep} "
    expression=""
    suppr=""
    local create_bash=0
    local do_tar=0

    old_IFS=$IFS     # sauvegarde du séparateur de champ
    IFS=$'\n'     # nouveau séparateur de champ, le caractère fin de ligne
    for line in $(cat ${input})
    do
        if [ -f "${git_rep}${line}" ]
        then
            expression=${expression}" \"${line}\""
            do_tar=1
        else # fichier supprimé
            suppr=${suppr}" \"${line}\""
            create_bash=1
        fi
    done
    IFS=$old_IFS     # rétablissement du séparateur de champ par défaut

    if [ $do_tar = 1 ]
    then
        echo "#!/bin/bash" > tmp_bash.sh
        echo "tar $option -czf $output $expression" >> tmp_bash.sh
        chmod +x tmp_bash.sh
        ./tmp_bash.sh
        rm -f tmp_bash.sh
        if [ -f $output ]
        then
            echo "archive $output created!"
        fi
    fi

    if [ $create_bash = 1 ]
    then
        create_bash_file ${output%%.*} "${suppr}"
    fi
}
#
# paramètres :
# $1 => output      nom du répertoire dans lequel mettre les fichiers
#
function create_dir()
{
    local output=$1
    local suppr=""
    local create_bash=0

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
        else # fichier supprimé
            suppr=${suppr}" \"${line}\""
            create_bash=1
        fi
    done

    if [ $create_bash = 1 ]
    then
        create_bash_file $output "${suppr}"
    fi

    echo "directory created!"
}
#
# paramètres :
# $1 => tag_prod    tag git correspondant à l'image de la prod
#
# return : ouput    nom du fichier listant les modifications
#
function create_diff_file()
{
    local tag_prod=$1

    local output="tmp.txt"

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
    local git_rep="$(git rev-parse --git-dir 2>/dev/null)"
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

#
# paramètres :
# $1 => output      nom du fichier à générer
# $2 => suppr       liste des fichiers à supprimer
#
function create_bash_file()
{
    local output=$1
    local tmp=$1
    local suppr=$2
    local i=1

    while [ -f $tmp".sh" ]
    do
        tmp=${output}${i}
        i=`expr $i + 1`
    done
    output=$tmp".sh"

    echo "#!/bin/bash" > $output
    echo "rm -f "$suppr >> $output
    chmod 755 $output

    if [ -f $output ]
    then
        echo "Bash script $output generated : you need to execute it!"
    else
        echo "Error with bash script generation, please execute this command line after deploying:"
        echo "rm -f "$suppr
    fi
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

    # Suppression des modifications locales et non commitées dans les fichiers
    git stash > /dev/null
    cd $dir_script

    input=$(create_diff_file ${2})

    if [ $TAR = "FALSE" ]
    then
        create_dir $1
    else
        create_tar $1
    fi

    if [ -f $input ]
    then
        rm $input
    fi

    cd $git_rep
    if [ ! $tag_dev = $initial_tag_dev ]
    then
        git checkout $initial_tag_dev --quiet
    fi
    # Remise en place des modifications locales non commitées
    git stash pop >& /dev/null
    cd $dir_script
fi
