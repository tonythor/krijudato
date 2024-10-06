# Team Krijudato
CUNY, Data 607, Fall 2023 

This data all comes from stack overflow. 

Team Members:
- Kri => **Kri**stin L.
- Ju => **Ju**lia F.
- Da => **Da**vid G. 
- To => **To**ny F. 



2024 team members:
- KL
- TF


To build:
```shell
# git clone into your working directory
# git pull origin develop

## Install python, let's use 3.10
hurricane:~ krijudato$ brew install python\@3.10
## Make sure you're using THIS version of python, not whatever one comes default with your mac.
hurricane:~ krijudato$ cd /opt/homebrew/Cellar/python\@3.10/3.10.14/bin/python3.10 -m venv .venv

## Now we activate this new venv
hurricane:krijudato afraser$ source ./.venv/bin/activate
(.venv) hurricane:krijudato afraser$

## Install the requirements 
(.venv) hurricane:krijudato afraser$ pip install -r requirements.txt

## edit your environment file

# edit > .venv/bin/activate 
#
# set python path to two things, krijudato/src, and site packages.
# _OLD_VIRTUAL_PATH="$PATH"
# PATH="$VIRTUAL_ENV/bin:$PATH"
# export PATH
# export PYTHONPATH=/Users/afraser/Documents/src/krijudato/src:/Users/afraser/Documents/src/krijudato/.venv/lib/python3.10/site-packages

# In the project directory, create/edit a file called .env, this makes tab completion work in visual studio code.
# (.venv) hurricane:krijudato afraser$ cat .env
# PYTHONPATH=/Users/afraser/Documents/src/krijudato/src:/Users/afraser/Documents/src/krijudato/.venv/lib/python3.10/site-packages(.venv) hurricane:krijudato afraser$

## edit your code nomally, if tab completion doens't work, reset your pyton interpreter to the python in 
# ./.venv/bin/python


# deactivate, reactivate
(.venv) hurricane:krijudato afraser$ deactivate
hurricane:krijudato afraser$ source ./.venv/bin/activate
(.venv) hurricane:krijudato afraser$

# run jupyter lab, or edit code in lussi/run.py
(.venv) hurricane:krijudato afraser$ jupyter lab



