from graphics import *
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt


"	Global variables	"
canvas_w	=	640
canvas_h	=	480

"	Function to plot a point on the canvas	"
def	putpxl(x,y,w,color):
	w.plotPixel(x,y,color)


"	Bressenham line drawing algorithm	"
"		Picked up straight from wikipedia	[http://en.wikipedia.org/wiki/Bresenham's_line_algorithm#Simplification]"
def	draw_line(x0,y0,x1,y1,w):
	dx	=	abs(x1-x0)
	dy	=	abs(y1-y0)
	
	if(x0<x1):
		sx	=	1
	else:
		sx	=	-1
	
	if(y0<y1):
		sy	=	1
	else:
		sy	=	-1
	
	err	=	dx-dy

	while(1):
		putpxl(x0,y0,w,color_rgb(0,0,0))

		if(x0==x1):
			if(y0==y1):
				break
		
		e2	=	2*err

		if(e2>-dy):
			err	=	err-dy
			x0	=	x0+sx
		
		if(e2<dx):
			err	=	err+dx
			y0	=	y0+sy
		
	print('Done with line')


def draw_line_anti(x0,y0,x1,y1,w):
	dx	=	abs(x1-x0)
	dy	=	abs(y1-y0)
	
	if(x0<x1):
		sx	=	1
	else:
		sx	=	-1
	
	if(y0<y1):
		sy	=	1
	else:
		sy	=	-1
	
	err	=	dx-dy
	v1  = dx-dy

	while(1):
		e2	=	2*err
		
		if(dx>=dy):
			if(v1>e2):
				shade1 = ((v1-e2)/dx)*127
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0,y0+1,w,color_rgb(shade2,shade2,shade2))
			else:
				shade1 = ((e2-v1)/dx)*127
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0,y0-1,w,color_rgb(shade2,shade2,shade2))
		else:
			if(v1<e2):
				shade1 = ((e2-v1)/dy)*127
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0+1,y0,w,color_rgb(shade2,shade2,shade2))
			else:
				shade1 = ((v1-e2)/dy)*127
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0-1,y0,w,color_rgb(shade2,shade2,shade2))
		
		
		if(x0==x1):
			if(y0==y1):
				break
		
		
		if(e2>-dy):
			err	=	err-dy
			x0	=	x0+sx
		
		if(e2<dx):
			err	=	err+dx
			y0	=	y0+sy
		
	print('Done with line')



def	plot_ycbcr_cube():
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	
	for y in range (0, 16):
		for cb in range (0, 4):
			for cr in range (0, 4):
				y1 = 16 + (y*14.6)
				cb1= 16 + (cb*74.66667)
				cr1= 16 + (cr*74.66667)
				
				r = (1.164*(y1 - 16) + 1.793*(cr1 - 128))
				g = (1.164*(y1 - 16) - 0.213*(cb1 - 128) - 0.533*(cr - 128))
				b = (1.164*(y1 - 16) + 2.112*(cb1 - 128))
				
				if(r<0):
					r = 0
				elif(r > 255):
					r = 255
				
				if(g<0):
					g = 0
				elif(g > 255):
					g = 255
				
				if(b<0):
					b = 0
				elif(b > 255):
					b = 255
				
				ax.scatter(y,cb,cr, c=color_rgb(r,g,b), marker='o', s=200)
	
	ax.set_xlabel('Y')
	ax.set_ylabel('Cb')
	ax.set_zlabel('Cr')
	
	plt.show()


"	Work Area	-	Write code to test models here ..."
"win = GraphWin('syn_canvas ' + str(canvas_w) + 'x' + str(canvas_h),canvas_w,canvas_h)"
""
"pt = Point(200,200)"
"pt.draw(win)"
""
"draw_line_anti(0,0,100,10,win)"
"draw_line_anti(0,0,10,100,win)"
" draw_line_anti(0,200,400,0,win) "
"draw_line_anti(400,0,0,200,win)"
"draw_line_anti(0,0,10,canvas_h,win)"
"draw_line_anti(0,0,canvas_w,20,win)"
"draw_line_anti(0,0,400,400,win)"


plot_ycbcr_cube()


input("waiting ...")
