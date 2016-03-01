


all: main.vala
	valac --pkg gtk+-3.0 --pkg gee-0.8 main.vala -X -lm -X -w -g
