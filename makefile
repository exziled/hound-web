
FILES = application sparks system .htaccess index.php

all:
	@echo "make deploy			Sync file changes with server"

deploy:
	rsync -r --delete $(FILES) houndplex.plextex.com:/var/www/hound

