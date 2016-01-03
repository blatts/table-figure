// -*- mode: C++ -*-
// Time-stamp: "2015-12-16 13:23:56 sb"

/*
  file       cell_table.asy
  copyright  (c) Sebastian Blatt 2015

  Create a self-rendering table structure similar to CSS/HTML using
  inheritance as shown in

    http://asymptote.sourceforge.net/doc/Structures.html

  We want to specify a table as a tree of nested rows and columns,
  where each row or column holds a sequence of table cells. We want to
  be able to specify the table layout conveniently in terms of
  percentages or actual units and let the table structure "render"
  itself into a vector of rectangular figure regions that can be
  indexed conveniently.

 */

import logging;

void cell_table_message(string msg) = logging_message_fc("cell_table.asy");
void cell_table_warning(string msg) = logging_warning_fc("cell_table.asy");


struct Cell {
    // A negative value indicates inheritance from parent, such that
    // positions and sizes can be calculated dynamically.
    real width;
    real height;

    // Inner padding, default to zero
    real padding_w;
    real padding_h;

    // A convenience label that allows addressing each cell later by label.
    string label;

    // Bottom left of the rendered cell. This gets assigned at the
    // very end by render().
    pair bottom_left;

    // Pointer to parent cell. Leave this unassigned until the Cell is
    // added to a table. parent == null indicates a root cell.
    Cell parent = null;

    // Pointers to child cells. Fill with push() below.
    Cell[] children;

    void operator init(real width = -1,
                       real height = -1,
                       real padding_w = 0,
                       real padding_h = 0,
                       string label = "")
    {
      this.width = width;
      this.height = height;
      this.padding_w = padding_w;
      this.padding_h = padding_h;
      this.label = label;

      bottom_left = (0, 0);
    }

    void push(Cell child){
      child.parent = this;
      children.push(child);
    }

    Cell index(int idx){
      if(idx < 0 || idx >= children.length){
        cell_table_warning("Cell::index: Index " + format("%g", idx)
                           + " not in [0, "
                           + format("%g", children.length-1) + "]");
      }
      return children[idx];
    }

    bool is_fully_defined(){
      if(width < 0 || height < 0) {
        return false;
      }
      return true;
    }

    string represent(){
      return "<Cell"
      + (width >= 0 ? " width=" + format("%g", width) : "")
      + (height >= 0 ? " height=" + format("%g", height) : "")
      + (label == "" ? "" : " label=\"" + label + "\"")
      + "/>";
    }

    // check if the current cell is fully defined. Do not iterate
    // over children because a base Cell should not know how to do
    // the geometry. Leave this to the specializations in Column and
    // Row.
    void render(Cell[] cells){
      if(is_fully_defined()){
        if(label != ""){
          cell_table_message("Adding Cell \"" + label + "\"");
          cells.push(this);
        }
      }
      else{
        cell_table_warning("Cell::render: Cell is not fully defined:\n  "
                           + represent());
      }
    }
};


struct Row {
    Cell base; // base data type, public inheritance

    void operator init(real width = -1,
                       real height = -1,
                       real padding_w = 0,
                       real padding_h = 0,
                       string label = "")
    {
      base.operator init(width, height, padding_w, padding_h, label);
    }

    // virtual function overrides base.push
    void push(Cell cell){
      // ensure that cells always span full row height
      cell.height = -1;
      base.children.push(cell);
    }
    base.push = push;


    // virtual function overrides base.represent
    string represent(){
      string rc = "<Row"
      + (base.width >= 0 ? " width=" + format("%g", base.width) : "")
      + (base.height >= 0 ? " height=" + format("%g", base.height) : "")
      + (base.padding_w > 0 ? " padding_w=" + format("%g", base.padding_w) : "")
      + (base.padding_h > 0 ? " padding_h=" + format("%g", base.padding_h) : "")
      + (base.label == "" ? "" : " label=\"" + base.label + "\"")
      + ">\n";
      for(int i=0; i<base.children.length; ++i){
        rc += "  " + base.children[i].represent() + "\n";
      }
      return rc + "</Row>";
    }
    base.represent = represent;


    void render(Cell[] cells){
      if(base.is_fully_defined()){
        // do we want the actual cell?
        if(base.label != ""){
          cells.push(base);
        }

        // Check what's missing
        int n_float = 0;
        real width_taken = 0;
        for(int i=0; i<base.children.length; ++i){
          Cell c = base.children[i];
          if(c.width < 0){
            ++n_float;
          }
          else{
            width_taken += c.width;
          }
        }

        // Fix sizes and bottom_left, accounting for inner padding of the row
        pair bl = base.bottom_left + (base.padding_w, base.padding_h);
        for(int i=0; i<base.children.length; ++i){
          Cell c = base.children[i];
          if(c.height < 0){
            c.height = base.height - 2 * base.padding_h;
          }
          if(c.width < 0){
            c.width = (base.width - 2*base.padding_w - width_taken) / n_float;
          }
          c.bottom_left = bl;
          c.render(cells);

          bl += (c.width, 0);
        }
      }
      else{
        cell_table_warning("Row::render: Cell is not fully defined:\n  "
                           + base.represent());
      }
    }
    base.render = render;

};

Cell operator cast(Row row) {
  return row.base;
}

struct Column {
    Cell base; // base data type, public inheritance

    void operator init(real width = -1,
                       real height = -1,
                       real padding_w = 0,
                       real padding_h = 0,
                       string label = "")
    {
      base.operator init(width, height, padding_w, padding_h, label);
    }

    // virtual function overrides base.push
    void push(Cell cell){
      // ensure that cells always span full column width
      cell.width = -1;
      base.children.push(cell);
    }
    base.push = push;


    // virtual function overrides base.represent
    string represent(){
      string rc = "<Column"
      + (base.width >= 0 ? " width=" + format("%g", base.width) : "")
      + (base.height >= 0 ? " height=" + format("%g", base.height) : "")
      + (base.padding_w > 0 ? " padding_w=" + format("%g", base.padding_w) : "")
      + (base.padding_h > 0 ? " padding_h=" + format("%g", base.padding_h) : "")
      + (base.label == "" ? "" : " label=\"" + base.label + "\"")
      + ">\n";
      for(int i=0; i<base.children.length; ++i){
        rc += "  " + base.children[i].represent() + "\n";
      }
      return rc + "</Column>";
    }
    base.represent = represent;


    void render(Cell[] cells){
      if(base.is_fully_defined()){
        // do we want the actual cell?
        if(base.label != ""){
          cells.push(base);
        }

        // Check what's missing
        int n_float = 0;
        real height_taken = 0;
        for(int i=0; i<base.children.length; ++i){
          Cell c = base.children[i];
          if(c.height < 0){
            ++n_float;
          }
          else{
            height_taken += c.height;
          }
        }

        // Fix sizes and bottom_left, accounting for inner padding of the column
        pair tl = base.bottom_left + (0, base.height - base.padding_h);
        for(int i=0; i<base.children.length; ++i){
          Cell c = base.children[i];
          if(c.width < 0){
            c.width = base.width - 2 * base.padding_w;
          }
          if(c.height < 0){
            c.height = (base.height - 2 * base.padding_h - height_taken) / n_float;
          }
          tl -= (0, c.height);
          c.bottom_left = tl;
          c.render(cells);
        }

      }
      else{
        cell_table_warning("Column::render: Cell is not fully defined:\n  "
                           + base.represent());
      }
    }
    base.render = render;
};

Cell operator cast(Column column) {
  return column.base;
}

// We do not seem to have dictionaries string -> Cell, so we
// create a simple holder for the mapped vectors. This structure
// will get populated when rendering the table and only contains
// cells of interest, i.e. cells for which the user assigned a
// label.
//
// We also cannot do forward declaration, so we must do the
// nesting trick described here
//
//   http://asymptote.sourceforge.net/FAQ/section7.html#cirdep
//
// None of this worked well. Instead, go back to simplest idea: let
// Cell.render() return an array of Cells and generate CellTable from
// that.
//
struct CellTable {
    string[] labels;
    Cell[] cells;
    int N;

    void operator init(){
      this.N = 0;
    }

    void push(Cell cell){
      labels.push(cell.label);
      cells.push(cell);
      ++N;
    }

    void append(Cell[] cells){
      for(int i=0; i<cells.length; ++i){
        push(cells[i]);
      }
    }

    Cell index(string label){
      for(int i=0; i<N; ++i){
        if(labels[i] == label){
          return cells[i];
        }
      }
      cell_table_warning("CellTable::index: Did not find label \"" + label + "\"");
      return null;
    }

    string represent() {
      string rc = "";
      for(int i=0; i<N; ++i){
        rc += labels[i] + ": " + cells[i].represent();
      }
      return rc;
    }
};

CellTable layout_and_render(Cell root_cell){
  CellTable rc = CellTable();
  Cell[] cells;
  root_cell.render(cells);
  rc.append(cells);
  return rc;
}
