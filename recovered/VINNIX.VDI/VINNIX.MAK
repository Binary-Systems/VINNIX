;
      0000 0000 typedef	char	BYTE;
      0000 0000 
      0000 0000 #endif
      0000 0000 
      0000 0000 strlen(s)  /* length of string */
      0007 0000 char *s;
      0007 0000 {
      0007 0000   char *p=s;
      0009 0000 
      0009 0000   while (*p!='\0')
      0011 0000     p++;
      001A 0000   return(p-s);
      0020 0000 }
      0025 0000 
      0025 0000 strcpy(s, t)  /* copy t to s; pointer version 3 */