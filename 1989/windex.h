/* a UNIX-like window package for VINNIX */

#define	MAXWINDOWS	3

typedef struct {
	int	X;
	int	Y;
} coordinate;

typedef struct {
	char		Name[10];
	coordinate	UpperLeft;
	coordinate	LowerRight;
} window_descriptor;
