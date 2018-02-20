#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <allegro5\allegro.h>
#include <allegro5\allegro_image.h>
#include <allegro5\allegro_memfile.h>

#define OFFSET 54
#define HSIZE 2
#define HWIDTH 18
#define HHEIGHT 22
#define HDRAWSIZE 34

extern "C" void draw(unsigned char* buf, int width, int height, int a, int b);

void getInput(int& w, int& h, int& a, int& b) {
	printf("A: ");
	scanf("%d", &a);
	printf("B: ");
	scanf("%d", &b);
	printf("W: ");
	scanf("%d", &w);
	printf("H: ");
	scanf("%d", &h);
}

void prepareSize(int& width, int& height, int& size) {
	int padd = width % 4;
	size = 3 * width * height + padd * height + OFFSET;
}

void prepareBmpHeader(unsigned char* bmpHeader, int width, int height, int size) {
	int* intLoc;

	intLoc = (int*)(&bmpHeader[HSIZE]);
	*intLoc = size;
	intLoc = (int*)(&bmpHeader[HWIDTH]);
	*intLoc = width;
	intLoc = (int*)(&bmpHeader[HHEIGHT]);
	*intLoc = height;
	intLoc = (int*)(&bmpHeader[HDRAWSIZE]);
	*intLoc = width * height;
}

void prepareBuffer(unsigned char** buffer, unsigned char* bmpHeader, int size) {
	if (*buffer != NULL)
		free(*buffer);
	*buffer = (unsigned char*)malloc(size);
	memset(*buffer, 0xFF, size);
	memcpy(*buffer, bmpHeader, OFFSET);
}

int main() {
	int size = 0, width = 0, height = 0;
	int a = 0, b = 0;
	unsigned char* buffer = NULL;
	unsigned char bmpHeader[OFFSET] = {
		0x42,0x4d,
		0x00,0x00,0x00,0x00,		//size [2]
		0x00,0x00,0x00,0x00,
		0x36,0x00,0x00,0x00,
		0x28,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,		//width [18]
		0x00,0x00,0x00,0x00,		//height [22]
		0x01,0x00,
		0x18,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,		//drawing size [34]
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00
	};
	
	al_init();
	al_init_image_addon();
	ALLEGRO_DISPLAY* disp = NULL;
	ALLEGRO_BITMAP* bitmap = NULL;
	ALLEGRO_FILE* file = NULL;

	while (1) {
		getInput(width, height, a, b);
		prepareSize(width, height, size);
		prepareBmpHeader(bmpHeader, width, height, size);
		prepareBuffer(&buffer, bmpHeader, size);
		draw(buffer, width, height, a, b);

		if (disp != NULL)
			al_destroy_display(disp);
		disp = al_create_display(width, height);
		file = al_open_memfile(buffer, size, "r");
		bitmap = al_load_bitmap_f(file, ".bmp");
		al_draw_bitmap(bitmap, 0, 0, 0);
		al_flip_display();
	}
	return 0;
}