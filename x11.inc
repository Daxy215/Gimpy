; Window stuff

; Display *XOpenDisplay(char *display_name)
extern XOpenDisplay

; int XDefaultScreen(Display *display)
extern XDefaultScreen                    ; Returns an ID representing the default screen number

; Window XRootWindow(Display *display, int screen_number)
extern XRootWindow

; int XStoreName(Display *display, Window w, char *window_name);
extern XStoreName

; int XSelectInput(Display *display, Window w, long event_mask);
extern XSelectInput
%define NoEventMask               0x00000000
%define KeyPressMask              0x00000001
%define KeyReleaseMask            0x00000002
%define ButtonPressMask           0x00000004
%define ButtonReleaseMask         0x00000008
%define EnterWindowMask           0x00000010
%define LeaveWindowMask           0x00000020
%define PointerMotionMask         0x00000040
%define PointerMotionHintMask     0x00000080
%define Button1MotionMask         0x00000100
%define Button2MotionMask         0x00000200
%define Button3MotionMask         0x00000400
%define Button4MotionMask         0x00000800
%define Button5MotionMask         0x00001000
%define ButtonMotionMask          0x00002000
%define KeymapStateMask           0x00004000
%define ExposureMask              0x00008000
%define VisibilityChangeMask      0x00010000
%define StructureNotifyMask       0x00020000
%define ResizeRedirectMask        0x00040000
%define SubstructureNotifyMask    0x00080000
%define SubstructureRedirectMask  0x00100000
%define FocusChangeMask           0x00200000
%define PropertyChangeMask        0x00400000
%define ColormapChangeMask        0x00800000
%define OwnerGrabButtonMask       0x01000000

; int XMapWindow(Display *display, Window w);
extern XMapWindow

; Window XCreateSimpleWindow(
;     Display *display,
;     Window parent,
;     int x,
;     int y,
;     unsigned int width,
;     unsigned int height,
;     unsigned int border_width,
;     unsigned long border,
;     unsigned long background
; );
extern XCreateSimpleWindow

extern XSync
extern XFlush

; int XNextEvent(Display *display, XEvent *event_return);
extern XNextEvent
%define KeyPressEventType              2
%define KeyReleaseEventType            3
%define ButtonPressEventType           4
%define ButtonReleaseEventType         5
%define MotionNotifyEventType          6
%define EnterNotifyEventType           7
%define LeaveNotifyEventType           8
%define FocusInEventType               9
%define FocusOutEventType              10
%define KeymapNotifyEventType          11
%define ExposeEventType                12
%define GraphicsExposeEventType        13
%define NoExposeEventType              14
%define VisibilityNotifyEventType      15
%define CreateNotifyEventType          16
%define DestroyNotifyEventType         17
%define UnmapNotifyEventType           18
%define MapNotifyEventType             19
%define MapRequestEventType            20
%define ReparentNotifyEventType        21
%define ConfigureNotifyEventType       22
%define ConfigureRequestEventType      23
%define GravityNotifyEventType         24
%define ResizeRequestEventType         25
%define CirculateNotifyEventType       26
%define CirculateRequestEventType      27
%define PropertyNotifyEventType        28
%define SelectionClearEventType        29
%define SelectionRequestEventType      30
%define SelectionNotifyEventType       31
%define ColormapNotifyEventType        32
%define ClientMessageEventType         33
%define MappingNotifyEventType         34
%define GenericEventEventType          35

; int XLookupString(XKeyEvent *ev, char *buf, int nbytes, KeySym *ks_return, XComposeStatus *status)
extern XLookupString

; GC XCreateGC(Display *display, Drawable d, unsigned long valuemask, XGCValues *values);
extern XCreateGC
%define GCFunction          0x00000001
%define GCPlaneMask         0x00000002
%define GCForeground        0x00000004
%define GCBackground        0x00000008
%define GCLineWidth         0x00000010
%define GCLineStyle         0x00000020
%define GCCapStyle          0x00000040
%define GCJoinStyle         0x00000080
%define GCFillStyle         0x00000100
%define GCFillRule          0x00000200
%define GCTile              0x00000400
%define GCStipple           0x00000800
%define GCTileStipXOrigin   0x00001000
%define GCTileStipYOrigin   0x00002000
%define GCFont              0x00004000
%define GCSubwindowMode     0x00008000
%define GCGraphicsExposures 0x00010000
%define GCClipXOrigin       0x00020000
%define GCClipYOrigin       0x00040000
%define GCClipMask          0x00080000
%define GCDashOffset        0x00100000
%define GCDashList          0x00200000
%define GCArcMode           0x00400000

; XFontStruct *XLoadQueryFont(Display *display, const char *name);
extern XLoadQueryFont                    ; Returns NULL if the font fails to load (XLoadFont doesn't)

; int XSetFont(Display *display, GC gc, Font font);
extern XSetFont

; int XSetForeground(Display *display, GC gc, unsigned long foreground);
extern XSetForeground

; int XDrawString(Display *display, Drawable d, GC gc, int x, int y, const char *string, int length);
extern XDrawString

; int XDestroyWindow(Display *display, Window w);
extern XDestroyWindow

; int XCloseDisplay(Display *display);
extern XCloseDisplay
