/* a UNIX-like string package */
#include	<c:\include\stdio.h>

strlen(s)  /* length of string */
char *s;
{
  char *p=s;

  while (*p!='\0')
    p++;
  return(p-s);
}

strcpy(s, t)  /* copy t to s; pointer version 3 */
char *s, *t;
{
  while (*s++ = *t++);
}

strcmp(s, t)  /* return <0 if s<t, 0 if s==t, >0 if s>t */
char *s, *t;
{
  for ( ; *s==*t; s++, t++)
    if (*s=='\0')
      return(0);
  return(*s-*t);
}

fputs(s, iop)
register char	*s;
register int	iop;
{
  char	c;

  while (c = *s++)
    putc(c, iop);
}

char *fgets(s, n, iop)
char	*s;
int	n;
int	iop;
{
  int	c;
  char	*cs;

  cs=s;
  while (--n>0 && (c=getc(iop)) != EOF)
    if ((*cs++ = c) == '\n') {
      if (iop==stdin) cs--;
      break;
    }
  *cs='\0';
  return((c==EOF && cs==s) ? NULL : s);
}

