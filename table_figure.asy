// -*- mode: C++ -*-
// Time-stamp: "2016-01-03 22:27:51 sb"

/*
  file       table_figure.asy
  copyright  (c) Sebastian Blatt 2015, 2016


  Scaling down 2D graphs is subpanels seems to be doing the
  right thing now. Need to deal with subpanels where we do not want
  IgnoreAspect scaling.

*/

import cell_table;

import logging;

void table_figure_message(string msg) = logging_message_fc("t-f");
void table_figure_warning(string msg) = logging_warning_fc("t-f");


void draw_boundary(picture pic, pair bottom_left,
                   real width, real height,
                   real linewidth, pen p = currentpen)
{
  // Need to be careful with drawing rectangles because each line will
  // be `linewidth' wide. We need to make sure to only draw on the
  // inside!

  real x = linewidth / 2; // half linewidth offset

  guide g = bottom_left + (x, x);
  g = g -- (bottom_left + (width - x, x));
  g = g -- (bottom_left + (width - x, height - x));
  g = g -- (bottom_left + (x, height - x)) -- cycle;

  draw(pic, g, p + linewidth);
}

void draw_boundary_limit(picture pic, pair bottom_left,
                         real width, real height,
                         real linewidth, pen p = currentpen)
{
  guide g = bottom_left;
  g = g -- (bottom_left + (width, 0));
  g = g -- (bottom_left + (width, height));
  g = g -- (bottom_left + (0, height)) -- cycle;

  draw(pic, g, p + linewidth);
}


void draw_bounding_box(picture pic, pair bottom_left,
                       real width, real height,
                       pen p = nullpen)
{
  // Can do this since we assume bounding box is around full image anyway
  size(pic, width, height);

  // need empty square so that asymptote does not crop automatically.
  draw_boundary(pic, bottom_left, width, height, 0pt, nullpen);
}


// Try fitting picture P to a rectangle of size SZ. This will fail
// mostly for 2D graphs because things are stupid and asy cannot guess
// the actual size of the graph during the picture.fit() optimization
// routine.
//
// Brute force solution: Scale down the target area proportionally
// until it works...
//
struct FitData {
    picture source_picture;
    bool keep_aspect;
    frame fitted_picture;
    pair target_size;
    pair fitted_size;
    real attempt_scale;
    bool fit_successful;

    void operator init(picture source_picture_,
                       pair target_size_,
                       bool keep_aspect_ = false)
    {
      source_picture = source_picture_;
      keep_aspect = keep_aspect_;
      target_size = target_size_;
      attempt_scale = 1.0;
      fit_successful = false;
    }

    void print_result(){
      if(fit_successful){
        table_figure_message("  Fit successful: " + format("%g", fitted_size.x)
                             + " x " + format("%g", fitted_size.y)
                             + " (target " + format("%g", target_size.x)
                             + " x " + format("%g", target_size.y) + ")");
      }
      else{
        table_figure_message("  Fit NOT successful: " + format("%g", fitted_size.x)
                             + " x " + format("%g", fitted_size.y)
                             + " (target " + format("%g", target_size.x)
                             + " x " + format("%g", target_size.y) + ")");
      }
    }

    bool attempt_fit(){
      fitted_picture = source_picture.fit(target_size.x * attempt_scale,
                                          target_size.y * attempt_scale,
                                          keep_aspect ? Aspect : IgnoreAspect);
      fitted_size = max(fitted_picture) - min(fitted_picture);
      fit_successful = fitted_size.x <= target_size.x && fitted_size.y <= target_size.y;
      print_result();
      return fit_successful;
    }

    bool brute_force_fit(){
      if(attempt_fit()){
        return true;
      }

      real dscale = 0.01;
      int max_attempts = 20;
      int attempt = 0;
      for(attempt = 0; attempt < max_attempts; ++attempt){
        attempt_scale -= dscale;

        table_figure_message("  Refit attempt " + format("%d", attempt)
                             + ", scale down target by "
                             + format("%g", attempt_scale) + " and retry");
        if(attempt_fit()){
          break;
        }
      }

      // If we fell through max_attempts, assume something went wrong
      // and punt.
      if(attempt >= max_attempts-1){
        table_figure_warning("Too many fit attempts. I will assume it's YOUR fault "
                             + "and let asy enlarge as it wants.");
        attempt_scale = 1.0;
        return attempt_fit();
      }
      return true;
    }

    // Same as above, but try to be clever and do a binary search.
    bool brute_force_fit2(){
      if(attempt_fit()){
        return true;
      }

      real scale_success = 0.0;
      real scale_fail = 1.0;
      real scale_prev = 1.0;

      int max_attempts = 20;
      int attempt = 0;
      for(attempt = 0; attempt < max_attempts; ++attempt){
        scale_prev = attempt_scale;
        if(fit_successful){
          attempt_scale = (scale_fail + scale_prev) / 2;
          scale_success = scale_prev;
        }
        else{
          // Don't waste time going from 1 -> 0.5 on first iteration
          if(attempt == 0){
            attempt_scale = 0.95;
          }
          else{
            attempt_scale = (scale_success + scale_prev) / 2;
            scale_fail = scale_prev;
          }
        }

        table_figure_message("  Refit attempt " + format("%d", attempt)
                             + ", scale down target by "
                             + format("%g", attempt_scale) + " and retry");
        attempt_fit();
      }

      if(attempt >= max_attempts-1 && !fit_successful){
        table_figure_message("  Last success with scale "
                             + format("%g", scale_prev) + ", rescale");
        attempt_scale = scale_prev;
        attempt_fit();
      }
      return true;
    }
};


struct TableFigure {
    real width;
    real height;

    Cell root_cell;
    CellTable layout;
    int N;

    picture top_figure;
    picture[] panels;

    void operator init(Cell root_cell,
                       real width,
                       real height)
    {
      this.width = width;
      this.height = height;
      this.top_figure = new picture;
      draw_bounding_box(this.top_figure, (0, 0), this.width,
                        this.height, nullpen);

      this.root_cell = root_cell;

      this.layout = layout_and_render(this.root_cell);
      this.N = layout.N;

      table_figure_message("Create (" + format("%g", width) + ", "
                           + format("%g", height) + ") pt figure with "
                           + format("%d", N) + " panels.");

      this.panels = new picture[];
      for(int i=0; i<this.N; ++i){
        picture p = new picture;
        Cell c = this.layout.cells[i];
        size(p, c.width, c.height, Aspect);
        this.panels.push(p);
      }
    }

    int index(int i){
      if(i < 0 || i >= N){
        table_figure_warning("Invalid panel index : " + format("%d", i)
                          + " not in [0, " + format("%d", N) + "]");
      }
      return i;
    }

    picture index_panel(int i){
      int idx = index(i);
      return panels[idx];
    }

    Cell index_cell(int i){
      int idx = index(i);
      return layout.cells[idx];
    }

    void draw_cell_boundaries(bool careful_about_boundary = true){
      real linewidth = 1pt;

      for(int i=0; i<N; ++i){
        Cell c = layout.cells[i];
        if(careful_about_boundary){
          draw_boundary(top_figure, c.bottom_left, c.width, c.height,
                        linewidth, black);
        }
        else{
          draw_boundary_limit(top_figure, c.bottom_left, c.width, c.height,
                              linewidth, black);
        }
      }
    }

    // Simple debugging to test the effect of point(picture, pair) and
    // truepoint(picture, pair) vs. bare pair.
    static void debug_point(picture p, pair pt, pen pn = currentpen){
      dot(p, pt, pn);
      label(p, Label("{\tiny (" + format("%g", pt.x) + ","
                     + format("%g", pt.y) + ")}", pn),
            pt, SE);
    }

    // Add labels to the panels. Add these in the top figure to ensure that
    // the scaling is the same.
    void panel_labels(bool automatic = true,
                      bool capitalize = false,
                      bool leftparen = false,
                      bool rightparen = false,
                      int corner = 0,
                      pen label_pen = fontsize(8) + gray(0.2),
                      pair label_offset = (0pt, 0pt)
                     )
    {
      string[] alphabet = {"a", "b", "c", "d", "e", "f", "g", "h"};
      string[] Alphabet = {"A", "B", "C", "D", "E", "F", "G", "H"};
      align[] directions = {NE, SE, SW, NW};
      //align[] directions = {SW, NW, NE, SE};
      // Should offset with fontsize(label_pen)
      // linewidth(label_pen), linetype, offset, scale, adjust

      string[] tag_list = capitalize ? Alphabet : alphabet;

      for(int i=0; i<N; ++i){
        Cell c = this.index_cell(i);

        string tag = automatic ? tag_list[i] : c.label;
        tag = (leftparen ? "(" : "") + tag + (rightparen ? ")" : "");

        pair pos = c.bottom_left;
        if(corner == 1){
          pos += (0, c.height);
        }
        else if(corner == 2){
          pos += (c.width, c.height);
        }
        else {
          pos += (c.width, 0);
        }

        label(top_figure,
              Label("{\bfseries " + tag + "}", label_pen),
              pos+label_offset, directions[corner]);

        //debug_point(top_figure, pos + label_offset, green);
      }
    }


    void shipout(bool draw_cell_boundaries_ = true,
                 bool draw_cell_boundaries_carefully_ = true
                )
    {
      if(draw_cell_boundaries_){
        draw_cell_boundaries(draw_cell_boundaries_carefully_);
      }

      for(int i=0; i<N; ++i){
        Cell c = layout.cells[i];
        picture q = panels[i];

        table_figure_message("Fit panel \"" + index_cell(i).label + "\"");
        FitData fd = FitData(q, (c.width, c.height), false);
        fd.brute_force_fit2();
        pair dx = point(fd.fitted_picture, SW);

        add(top_figure, fd.fitted_picture, c.bottom_left - dx);
      }

      // Final size can also fail!!! Need to do scaling here as well.
      table_figure_message("Fit top figure");
      FitData fd = FitData(top_figure, (width, height), true);
      fd.brute_force_fit2();

      shipout(fd.fitted_picture, "pdf");
    }

    static void draw_and_size_panel(picture panel,
                                    void draw_panel_callback(picture))
    {
      size(panel, panel.xsize, panel.ysize, IgnoreAspect);
      draw_panel_callback(panel);
    }

};


TableFigure table_figure_create_grid(real width,
                                     real height,
                                     int Nx,
                                     int Ny,
                                     real pad_w = 0,
                                     real pad_h = 0)
{
  Column root_cell = Column(width, height, padding_h = pad_h);

  for(int i=0; i<Ny; ++i){
    Row row = Row(padding_w = pad_w);
    for(int j=0; j<Nx; ++j){
      Cell cell = Cell(label = format("%d", j*Nx + i));
      row.push(cell);
    }
    root_cell.push(row);
  }

  return TableFigure(root_cell, width, height);
}
