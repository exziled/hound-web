
FILES = application sparks system .htaccess index.php EventParser

all:
	@echo "make deploy			Sync file changes with server"

deploy:
	rsync -r --delete $(FILES) houndplex.plextex.com:/var/www/hound

