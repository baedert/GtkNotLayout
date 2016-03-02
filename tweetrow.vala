


class TweetRow : LayoutManager {
  private Gtk.Image avatar_image = new Gtk.Image.from_icon_name ("corebird", Gtk.IconSize.DIALOG);
  private Gtk.Button name_button = new Gtk.Button.with_label ("Schupp & Wupp");
  private Gtk.Label screen_name_label = new Gtk.Label ("@baedert");


  public TweetRow () {
    avatar_image.set_size_request (48, 48);
    avatar_image.margin = 6;
    this.add (avatar_image);

    this.add (name_button);

    screen_name_label.get_style_context ().add_class ("dim-label");
    this.add (screen_name_label);
  }

  protected override Size measure (int dir) {
    Size size = {};

    if (dir == HORIZONTAL) {
      size.set (sum_widths ({avatar_image, name_button, screen_name_label}));
    } else { /* VERTICAL */
      size.set (max_heights ({avatar_image, name_button, screen_name_label}));
    }

    return size;
  }

  protected override void layout (int width, int height) {
    int x = 0;
    int y = 0;
    int w, h;

    x += this.allocate_min_height (avatar_image, x, y, -1);

    /* TODO: We need API to just allocate the in size in both dimensions
       and get both the allocate width and the allocated height back... */
    //message ("x1: %d", x);
    this.allocate_min_size (name_button, x, y, out w, out h);
    x += w;

    this.allocate_min_size (screen_name_label, x, y, out w, out h);
  }
}
