#define	Clear	printf("\033*")
#define	Home	printf("\033{")
#define Cursor(X,Y)	printf("\033=%c%c", (Y)+32, (X)+32)

#define TopLeft		"\033H2"
#define TopRight	"\033H3"
#define BottomLeft	"\033H1"
#define BottomRight	"\033H5"
#define Horizontal	"\033H:"
#define Vertical	"\033H6"

#define Reverse	printf("\033G4")
#define Normal	printf("\033G0")
#define Blank	printf("\033G3")
#define RevBlank	printf("\033G5")

#define	UP	11
#define DOWN	10
#define	LEFT	8
#define	RIGHT	12

#define MSG(STRING)	printf("\033F%s\015", STRING)

#define Print_ON	printf("\030");
#define	Print_OFF	printf("\024");

