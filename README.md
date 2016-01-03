Table-figure is an attempt at creating a flexible grid layout for
the asymptote language at the picture object level.

A typical use case are complex figures for publication in experimental
physics journals. These figures typically consist of multiple panels
on a grid, typically aligned carefully to allow visual comparison
between different sets of data.

The module allows specifying a grid layout similar to tables
consisting of cells in rows and columns (cf. HTML). The height and
width of the cells can be specified in absolute units or can be left
unspecified (the available space will then be used accordingly).

This design allows separating the complex figure creation for each
panel to be separate from the grid layout (with labels) for the
composite figure and greatly simplifies the creation of complex
figures.

Because of the powerful late object scaling intrinsic to asymptote,
such a grid layout is notoriously difficult to achieve cleanly. This
module is an attempt at easing the creation of such figures.

A complex example created entirely in asymptote is Fig. 2 of Phys.
Rev. A 92, 021402(R) (2015)
(http://dx.doi.org/10.1103/PhysRevA.92.021402). The figure can seen
without having access to the full paper by clicking on the thumbnail
in the abstract.
