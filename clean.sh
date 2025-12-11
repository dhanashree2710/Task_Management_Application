#!/usr/bin/env bash

echo "Enter the feature name (use underscores for spaces. i.e. training_library)"

echo "Feature name: "
read -r name

declare -a libs=(
    ""
    "/data" 
    "/data/models" 
    "/data/repositories"
    "/domain"
    "/domain/entities"
    "/domain/repositories"
    "/domain/usecases"
    "/presentation"
    "/presentation/bloc"
    "/presentation/pages"
    "/presentation/views"
    "/presentation/widgets"
)

declare -a tests=(
    ""
    "/data"
    "/data/models"
    "/data/repositories"
    "/domain"
    "/domain/usecases"
    "/presentation"
    "/presentation/bloc"
    "/presentation/pages"
    "/presentation/views"
    "/presentation/widgets"
)


make_dir()
{
    # expects to be called as: make_dir name prepath postpath
    DIR_PATH=$2$1$3
    if [ -d "$DIR_PATH" ] 
    then
        echo "$DIR_PATH exists" 
    else
        mkdir ${DIR_PATH}
        echo "Created $DIR_PATH"
    fi
}

for i in "${libs[@]}"
do
   make_dir $name "lib/modules/" $i
done


for i in "${tests[@]}"
do  
   make_dir $name "test/modules/" $i
done