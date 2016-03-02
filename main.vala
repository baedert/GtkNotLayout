/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

const int HORIZONTAL = 0;
const int VERTICAL   = 1;
struct Size {
  int minimal;
  int natural;

  public void set (Size s) {
    this.minimal = s.minimal;
    this.natural = s.natural;
  }
}

Size max_size (Size s1, Size s2) {
  Size ret = {};
  /* Order after min size. */
  if (s1.minimal < s2.minimal) {
    ret.minimal = s2.minimal;
    ret.natural = s2.natural;
  } else {
    ret.minimal = s1.minimal;
    ret.natural = s1.natural;
  }

  return ret;
}

Size add_sizes (Size s1, Size s2) {
  Size ret = {};
  ret.minimal = s1.minimal + s2.minimal;
  ret.natural = s1.natural + s2.natural;

  return ret;
}

Size widget_width (Gtk.Widget w) {
  Size ret = {};
  w.get_preferred_width (out ret.minimal, out ret.natural);
  return ret;
}
Size widget_height (Gtk.Widget w) {
  Size ret = {};
  w.get_preferred_height (out ret.minimal, out ret.natural);
  return ret;
}

Size sum_widths (Gtk.Widget[] widgets) {
  Size ret = {};

  foreach (unowned Gtk.Widget w in widgets) {
    int m, n;
    w.get_preferred_width (out m, out n);

    ret.minimal += m;
    ret.natural += n;
  }

  return ret;
}

Size max_heights (Gtk.Widget[] widgets) {
  Size ret = {};

  foreach (unowned Gtk.Widget w in widgets) {
    int m, n;
    w.get_preferred_height (out m, out n);

    ret.minimal = int.max (ret.minimal, m);
    ret.natural = int.max (ret.natural, n);
  }

  return ret;
}

abstract class LayoutManager : Gtk.Container {
  private Gee.ArrayList<Gtk.Widget> children = new Gee.ArrayList<Gtk.Widget> ();


  public override void add (Gtk.Widget widget) {
    widget.set_parent (this);
    this.children.add (widget);
  }

  public override void remove (Gtk.Widget widget) {
    this.children.remove (widget);
  }

  public override void forall_internal (bool include_internals,
                                        Gtk.Callback callback) {
    foreach (var w in this.children) {
      callback (w);
    }
  }

  construct {
    this.set_has_window (false);
  }

  protected abstract void layout (int width, int height);
  protected abstract Size measure (int dir);

  /* GtkWidget API {{{ */
  // TODO: Implement for_size variants
  public override void get_preferred_width (out int minimal, out int natural) {
    Size size = this.measure (HORIZONTAL);

    minimal = size.minimal;
    natural = size.natural;
  }

  public override void get_preferred_height (out int minimal, out int natural) {
    Size size = this.measure (VERTICAL);

    minimal = size.minimal;
    natural = size.natural;
  }
  /* }}} */

  private int get_allocated_x () {
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    return alloc.x;
  }

  private int get_allocated_y () {
    Gtk.Allocation alloc;
    this.get_allocation (out alloc);
    return alloc.y;
  }


  public void allocate_child (Gtk.Widget child, int x, int y, int width, int height) {
    int min, nat;
    child.get_preferred_width (out min, out nat);
    if (width < min) width = min;

    child.get_preferred_height (out min, out nat);
    if (height < min) height = min;


    Gtk.Allocation alloc = {};
    alloc.x = x + this.get_allocated_x ();
    alloc.y = y + this.get_allocated_y ();
    alloc.width = width;
    alloc.height = height;

    child.size_allocate (alloc);
  }

  public int allocate_min_width (Gtk.Widget child, int x, int y, int height) {
    assert (child.parent == this);
    height = int.max (1, height);
    int min, nat;
    child.get_preferred_width_for_height (height, out min, out nat);

    Gtk.Allocation alloc = {};
    alloc.x = x + this.get_allocated_x ();
    alloc.y = y + this.get_allocated_y ();
    alloc.width = min;
    alloc.height = height;

    child.size_allocate (alloc);
    return min;
  }

  public int allocate_min_height (Gtk.Widget child, int x, int y, int width) {
    assert (child.parent == this);
    //width = int.max (1, width);
    int min, nat;
    child.get_preferred_width (out min, out nat);
    width = int.max (width, min);
    child.get_preferred_height_for_width (width, out min, out nat);

    Gtk.Allocation alloc = {};
    alloc.x = x + this.get_allocated_x ();
    alloc.y = y + this.get_allocated_y ();
    alloc.width = width;
    alloc.height = min;

    child.size_allocate (alloc);
    return min;
  }

  public void allocate_min_size (Gtk.Widget child, int x, int y, out int width, out int height) {
    assert (child.parent == this);
    int min, nat;
    int min_width;
    child.get_preferred_width (out min_width, out nat);
    child.get_preferred_height_for_width (min_width, out min, out nat);

    Gtk.Allocation alloc = {};
    alloc.x = x + this.get_allocated_x ();
    alloc.y = y + this.get_allocated_y ();
    alloc.width = min_width;
    alloc.height = min;

    child.size_allocate (alloc);

    width = alloc.width;
    height = alloc.height;
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    this.set_allocation (allocation);

    this.layout (allocation.width, allocation.height);
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

class TestLayoutManager : LayoutManager {
  private Gtk.Button button1 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button2 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button3 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button4 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button5 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button6 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.Button button7 = new Gtk.Button.from_icon_name ("list-add-symbolic");
  private Gtk.ScrolledWindow scroller = new Gtk.ScrolledWindow (null, null);
  private Gtk.ListBox list_box = new Gtk.ListBox ();

  public TestLayoutManager () {
    this.add (button1);
    this.add (button2);
    this.add (button3);
    this.add (button4);
    this.add (button5);
    this.add (button6);
    this.add (button7);

    for (int i =  0; i < 20; i ++)
      list_box.add (new TweetRow ());

    scroller.min_content_height = 100;
    scroller.add (list_box);
    this.add (scroller);
  }

  protected override Size measure (int dir) {
    Size size = {};

    if (dir == HORIZONTAL) {
      size.set (max_size (sum_widths ({button1, button2, button3, button4, button5, button6, button7}),
                          widget_width (scroller))
                );
    } else { /* VERTICAL */
      size.set (add_sizes (max_heights ({button1, button2, button3, button4, button5, button6, button7}),
                           widget_height (scroller))
                );
    }

    return size;
  }

  protected override void layout (int width, int height) {
    int y = 0;
    int x = 0;

    Gtk.Widget[] buttons = {
      button1,
      button2,
      button3,
      button4,
      button5,
      button6,
      button7,
    };

    /* TODO: We should probably have some _spread_widgets helper function for this */
    /* Our width is at least the min width of all the buttons, so use max(width/n, min_width) per button */
    int button_size = width / 7;
    int extra_px = width - button_size * 7; /* Number of buttons getting an extra px */
    int extra_px_jump = extra_px > 0 ? (7 / extra_px) : 0;
    int index = 0;
    foreach (unowned Gtk.Widget w in buttons) {
      int h;
      if (extra_px_jump > 0 && index % extra_px_jump == 0) {
        h = this.allocate_min_height (w, x, 0, button_size + 1);
        x += button_size + 1;
      } else {
        h = this.allocate_min_height (w, x, 0, button_size);
        x += button_size;
      }

      // Let the next widget start at max(button_heights)
      y = int.max (y, h);
      index ++;
    }

    /* New row */
    x = 0;

    /* Rest of the height and full width for the scrolled window */
    this.allocate_child (scroller, x, y, width, height - y);
  }
}


void main (string[] args) {
  Gtk.init (ref args);
  var win = new Gtk.Window ();
  var bar = new Gtk.HeaderBar ();
  bar.show_close_button = true;
  win.set_titlebar (bar);

  var layout_manager = new TestLayoutManager ();
  win.add (layout_manager);

  win.show_all ();
  Gtk.main ();
}
