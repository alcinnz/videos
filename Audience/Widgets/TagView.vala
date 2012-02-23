
/*
  The panel on the right hand side
*/

namespace Audience.Widgets{
    
    public class TagView : GtkClutter.Actor{
        
        public bool expanded;
        public Gtk.Grid taggrid;
        public Gtk.ListStore playlist;
        public AudienceApp app;
        
        public TagView (AudienceApp app){
            this.app = app;
            
            var notebook = new Granite.Widgets.StaticNotebook ();
            
            /*tags*/
            taggrid = new Gtk.Grid ();
            taggrid.column_spacing = 10;
            taggrid.margin = 12;
            
            /*chapters*/
            var chaptergrid = new Gtk.Grid ();
            chaptergrid.margin = 12;
            chaptergrid.attach (new LLabel.markup ("<span weight='bold' font='20'>Go to...</span>"), 0, 0, 1, 1);
            
            chaptergrid.attach (
                new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU), 0, 1, 1, 1);
            chaptergrid.attach (new Gtk.Button.with_label ("Menu"), 1, 1, 1, 1);
            chaptergrid.attach (
                new Gtk.Image.from_icon_name ("folder-music-symbolic", Gtk.IconSize.MENU), 0, 2, 1, 1);
            chaptergrid.attach (new Gtk.Button.with_label ("Audio Menu"), 1, 2, 1, 1);
            chaptergrid.attach (
                new Gtk.Image.from_icon_name ("folder-videos-symbolic", Gtk.IconSize.MENU), 0, 3, 1, 1);
            chaptergrid.attach (new Gtk.Button.with_label ("Chapter Menu"), 1, 3, 1, 1);
            for (var i=1;i<10;i++){
                chaptergrid.attach (
                    new Gtk.Image.from_icon_name ("view-list-video-symbolic", Gtk.IconSize.MENU), 0, i+3, 1, 1);
                var bt = new Gtk.Button.with_label ("Chapter 0"+i.to_string ());
                bt.hexpand = true;
                chaptergrid.attach (bt, 1, i+3, 1, 1);
            }
            
            /*setup*/
            var setupgrid = new Gtk.Grid ();
            var languages = new Gtk.ComboBoxText ();
            var subtitles = new Gtk.ComboBoxText ();
            setupgrid.attach (new LLabel.markup (
                "<span weight='bold' font='20'>Setup</span>"), 0, 0, 1, 1);
            setupgrid.attach (new Gtk.Label ("Language"),  0, 1, 1, 1);
            setupgrid.attach (languages,                   1, 1, 1, 1);
            setupgrid.attach (new Gtk.Label ("Subtitles"), 0, 2, 1, 1);
            setupgrid.attach (subtitles,                   1, 2, 1, 1);
            setupgrid.column_homogeneous = true;
            setupgrid.margin = 12;
            
            languages.append ("eng", "English (UK)");
            languages.append ("de", "German");
            languages.append ("fr", "French");
            languages.active = 0;
            subtitles.append ("0", "None");
            subtitles.append ("eng", "English (UK");
            subtitles.append ("de", "German");
            subtitles.append ("fr", "French");
            subtitles.active = 0;
            
            /*playlist*/
            var playlistgrid    = new Gtk.Grid ();
            playlistgrid.margin = 12;
            playlist            = new Gtk.ListStore (4, typeof (Gdk.Pixbuf),  /*playing*/
                                                        typeof (Gdk.Pixbuf),  /*icon*/
                                                        typeof (string),      /*title*/
                                                        typeof (string));     /*filename*/
            var playlisttree    = new Gtk.TreeView.with_model (playlist);
            playlisttree.expand = true;
            playlisttree.headers_visible = false;
            var css = new Gtk.CssProvider ();
            try{
                css.load_from_data ("*{background-color:@bg_color;}", -1);
            }catch (Error e){warning (e.message);}
            playlisttree.get_style_context ().add_provider (css, 12000);
            
            playlisttree.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (),
                "pixbuf", 0);
            playlisttree.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (),
                "pixbuf", 1);
            playlisttree.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (),
                "text", 2);
            
            playlisttree.row_activated.connect ( (path ,col) => {
                Gtk.TreeIter iter;
                playlist.get_iter (out iter, path);
                string filename;
                playlist.get (iter, 3, out filename);
                app.open_file (filename);
            });
            
            playlistgrid.attach (new LLabel.markup (
                "<span weight='bold' font='20'>Playlist</span>"), 0, 0, 1, 1);
            playlistgrid.attach (playlisttree, 0, 1, 1, 1);
            
            notebook.append_page (playlistgrid, new Gtk.Label ("Playlist"));
            notebook.append_page (setupgrid, new Gtk.Label ("Setup"));
            notebook.append_page (chaptergrid, new Gtk.Label ("Chapters"));
            notebook.append_page (taggrid, new Gtk.Label ("Details"));
            
            ((Gtk.Bin)this.get_widget ()).add (notebook);
            
            notebook.show_all ();
            
            this.height = this.get_stage ().height;
            this.width  = 200;
            this.expanded = false;
        }
        
        public void add_play_item (string filename){
            try{
                Gtk.TreeIter iter;
                var ext = Audience.get_extension (filename);
                Gdk.Pixbuf pix = null;
                if (ext in Audience.audio)
                    pix = Gtk.IconTheme.get_default ().load_icon ("folder-music-symbolic", 16, 0);
                else
                    pix = Gtk.IconTheme.get_default ().load_icon ("folder-videos-symbolic", 16, 0);
                var playing = Gtk.IconTheme.get_default ().load_icon ("media-playback-start-symbolic", 16, 0);
                playlist.append (out iter);
                playlist.set (iter, 0, playing, 1, pix, 
                                    2, Audience.get_basename (filename), 3, filename);
            }catch (Error e){warning (e.message);}
            
        }
        
        public void expand (){
            var x2 = this.get_stage ().width - this.width;
            this.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
            this.expanded = true;
        }
        
        public void collapse (){
            var x2 = this.get_stage ().width;
            this.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
            this.expanded = false;
        }
        
        public void get_tags (string filename, bool set_title){
            var pipe = new Gst.Pipeline ("tagpipe");
            var src  = Gst.ElementFactory.make ("uridecodebin", "src");
            var sink = Gst.ElementFactory.make ("fakesink", "sink");
            src.set ("uri", File.new_for_commandline_arg (filename).get_uri ());
            pipe.add_many (src, sink);
            
            pipe.set_state (Gst.State.PAUSED);
            
            taggrid.foreach ( (w) => {taggrid.remove (w);});
            taggrid.attach (new LLabel.markup ("<span weight='bold' font='20'>Info</span>"), 0, 0, 1, 1);
            var index = 1;
            pipe.get_bus ().add_watch ( (bus, msg) => {
                if (msg.type == Gst.MessageType.TAG){
                    Gst.TagList tag_list;
                    msg.parse_tag (out tag_list);
                    tag_list.foreach ( (list, tag) => {
                        for (var i=0;i<list.get_tag_size (tag);i++){
                            var val = list.get_value_index (tag, i);
                            if (set_title && tag == "title")
                                this.app.mainwindow.title = val.strdup_contents ();
                            taggrid.attach (new LLabel.markup ("<b>"+tag+"</b>"), 0, index, 1, 1);
                            taggrid.attach (new LLabel (val.strdup_contents ()),  1, index, 1, 1);
                            taggrid.show_all ();
                            index ++;
                        }
                    });
                }else if (msg.type == Gst.MessageType.EOS)
                    pipe.set_state (Gst.State.NULL);
                return true;
            });
            pipe.set_state (Gst.State.PLAYING);
        }
    }
    
}