# check if .env file exists, if not, copy .env.template to .env
if [ ! -f .env ]; then
	cp .env.template .env
fi

