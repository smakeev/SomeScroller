# SomeScroller
SomeScroller is a infinity scrolling horizontal or vertical scroll library.
It contains Scroller view.
SomeScroller is a view containing a collection view that could present it's cells one by one vertically or horizontally.
User could set up number of visible elements on one screen and delimiter if needed.
If number of elements is bigger then number of elements on the screen scroller will allow user to sroll elements in both directions.
Elements will be scrolled infinity repeating.
If all elements are on the screen then user will not be able to scroll. If there is an empty space user could set up a gravity parameter.
Gravity means how to layout elements on the screen. They could be loceted to the left(top), right(bottom), centered or justefied on the screen.
Also user could provide the vector with percent of empty space for each gap we have.

The view item itself has a UIView as it's super class. User should provide it's width (in horizontal case) or height (in vertical case)
 and the number of visible elements. User could provide aspect ratio for all elements (one is the same for all always). Also user could provide delimiter and it's widht. The other size will be calculated based 
on these provided parameters. 
