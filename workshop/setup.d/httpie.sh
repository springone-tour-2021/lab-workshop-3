#!/bin/bash
# Install httpie
virtualenv /home/eduk8s/bin/httpie
source /home/eduk8s/bin/httpie/bin/activate
pip install httpie
deactivate

# Make sure the following line is in the file workshop/profile
#alias http="/home/eduk8s/bin/httpie/bin/http"

clear