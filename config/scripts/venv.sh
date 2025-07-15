python3 -m venv venv
source venv/Scripts/activate
# python.exe -m pip install --upgrade pip
pip install -r requirements.txt
mkdocs build --verbose
pip install mkdocs
