// -*- mode: C++ -*-
// Time-stamp: "2016-01-03 19:38:45 sb"

/*
  file       table_figure_test.asy
  copyright  (c) Sebastian Blatt 2015, 2016

 */

import cell_table;
import table_figure;

import graph;

void draw_graph(picture p){
  real f(real t) {return 1/t^(1/2);}

  //scale(p, Linear, Linear);
  scale(p, Log, Log);

  draw(p, graph(p, f, 0.1, 100), red);

  xlimits(p, 0.01, 100);
  ylimits(p, 0.01, 10);

  xaxis(p, "$x$", BottomTop, LeftTicks);
  yaxis(p, "$y$", LeftRight, RightTicks);
}

TableFigure create_table_figure(real w, real h){
  Column root_cell = Column(w, h);

  Row first_row = Row(height = h/3);
  Cell c1 = Cell(width = 0.75 * w, label = "A");
  Cell c2 = Cell(label = "B");
  first_row.push(c1);
  first_row.push(c2);

  Row second_row = Row();
  Cell c3 = Cell(label = "C");
  Cell c4 = Cell(width = 0.7 * w, label = "D");
  second_row.push(c3);
  second_row.push(c4);

  root_cell.push(first_row);
  root_cell.push(second_row);

  TableFigure f = TableFigure(root_cell, w, h);

  return f;
}

void main(){
  // Figure dimensions
  real width = 300;
  real golden_ratio = (1 + sqrt(5)) / 2;
  real height = width / golden_ratio;

  // draw borders around figure for positioning
  bool draw_region_borders = true;

  // use regular or custom grid layout
  bool use_regular_grid = false;

  TableFigure f;
  if(use_regular_grid){
    f = table_figure_create_grid(width, height, 2, 2);
  }
  else{
    f = create_table_figure(width, height);
  }

  for(int i=0; i<f.N; ++i){
    picture p = f.index_panel(i);
    f.draw_and_size_panel(p, draw_graph);
  }

  //f.panel_labels(automatic = false, capitalize = true, corner = 1);

  f.shipout(draw_region_borders);
}

main();

// table_figure_test.asy ends here
