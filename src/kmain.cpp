/** fb_write_cell:
 * Writes a character with the given foreground and background to position i
 * in the framebuffer.
 *
 * @param i The location in the framebuffer
 * @param c The character
 * @param fg The foreground color
 * @param bg The background color
 */
volatile char *fb = (volatile char *)0x000B8000;
void fb_write_cell(unsigned int i, char c, unsigned char fg, unsigned char bg)
{
  fb[i] = c;
  fb[i + 1] = ((bg & 0x0F) << 4) | (fg & 0x0F);
}

void fb_clear()
{
  for (unsigned int i = 0; i < 80 * 25 * 2; i += 2)
  {
    fb[i] = ' ';
    fb[i + 1] = 0x00;
  }
}

extern "C" void kmain()
{
  fb_clear();
  fb_write_cell(0, 'A', 0xF0, 0x00);
  fb_write_cell(2, 'B', 0x0F, 0x00);
}