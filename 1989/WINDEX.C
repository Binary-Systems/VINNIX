/* a UNIX-like window package for VINNIX */

#include	"c:\include\windex.h"
#include	"c:\include\wyse.h"

fopenw(name, ul, lr)
char		*name;
coordinate	*ul;
coordinate	*lr;
{
/* window_descriptor	window[MAXWINDOWS]; 
  int			windex; */
  register char			x, y;
  char				x1, x2, y1, y2;
  char				namelen, wlen;

  x1=ul->X;
  y1=ul->Y;
  x2=lr->X;
  y2=lr->Y;

  namelen=strlen(name);
  wlen=x2-x1;  
/*  strcpy(window[windex].Name, name);
  window[windex].UpperLeft.X = x1;
  window[windex].UpperLeft.Y = y1;
  window[windex].LowerRight.X = x2; 
  window[windex].LowerRight.Y = y2; */

  Cursor(x1,y1);
  printf(TopLeft);
  for (x=x1+1; x<=x2-1; x++) printf(Horizontal);
  printf(TopRight);

  for (y=y1+1; y<=y2-1; y++) {
    Cursor(x1,y); 
    printf(Vertical);
    for (x=x1+1; x<=x2-1; x++) {
      printf(" ");
    }
    printf(Vertical);
  }

  Cursor(x1,y2);
  printf(BottomLeft);
  for (x=x1+1; x<=x2-1; x++) printf(Horizontal);
  printf(BottomRight);

  if (namelen<wlen) {
    Cursor(x1+wlen/2-namelen/2-2, y1);
    Reverse;
    printf(" %s ", name);
    Normal;
  }
  Cursor(x1+1,y1+1);
/*  windex++;
  return(windex+2); */
  return(0);
}
