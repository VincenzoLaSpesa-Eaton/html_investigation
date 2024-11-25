/*This source code copyrighted by Lazy Foo' Productions 2004-2024
and may not be redistributed without written permission.*/

//Using SDL and standard IO
#include <SDL2/SDL.h>
#include <stdio.h>
#include "litehtml.h"
#include <stdexcept>
#include <string>

#include "cairo-pango-sdl/container_cairo_pango.h"
#include "web_page.h"

//Screen dimension constants
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;

char master_css[] = 
{
#include "master.css.inc"
,0
};

template<typename T>
static T fail(const char* caller = nullptr)
{
	std::string msg = "Not implemented ";
	if(caller)
		msg+= caller;
	throw std::logic_error(msg);
	return T{};
}


/*class context
{public:
	void load_master_stylesheet(char* master_css){fail<bool>(__PRETTY_FUNCTION__);	}
};*/

class SDL_Container : public container_cairo_pango 
{public:
	virtual void                            load_image(const char* src, const char* baseurl, bool redraw_on_ready)	{fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            set_caption(const char* caption) {fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            set_base_url(const char* base_url) {fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            on_anchor_click(const char* url, const litehtml::element::ptr& el){fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            on_mouse_event(const litehtml::element::ptr& el, litehtml::mouse_event event){fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            set_cursor(const char* cursor) {fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            import_css(litehtml::string& text, const litehtml::string& url, litehtml::string& baseurl){fail<bool>(__PRETTY_FUNCTION__);	}
	virtual void                            get_client_rect(litehtml::position& client) const {fail<bool>(__PRETTY_FUNCTION__);	}
	virtual cairo_surface_t* get_image(const std::string& url){return fail<cairo_surface_t*>(__PRETTY_FUNCTION__);	}
	virtual double get_screen_dpi() const {return fail<double>(__PRETTY_FUNCTION__);	}
	virtual int get_screen_width() const {return fail<int>(__PRETTY_FUNCTION__);	}
	virtual int get_screen_height() const {return fail<int>(__PRETTY_FUNCTION__);	}
	void draw(litehtml::document::ptr doc){fail<bool>(__PRETTY_FUNCTION__);	}

	
};

int main( int argc, char* args[] )
{
    //context ctx;
    SDL_Container container;

    // Load and parse HTML
    std::string html = "<html><body><h1>Hello, litehtml!</h1></body></html>";
	//ctx.load_master_stylesheet(master_css);
	
	std::string css = master_css;
    
	//litehtml::document::ptr doc = litehtml::document::createFromString(html.c_str(), &container, &ctx);
	litehtml::document::ptr doc = litehtml::document::createFromString(html.c_str(), &container, css);

    // Render the document
    doc->render(800); // Width of the rendering area

    // Draw the document (example using a custom draw method)
    container.draw(doc);

	//The window we'll be rendering to
	SDL_Window* window = NULL;
	
	//The surface contained by the window
	SDL_Surface* screenSurface = NULL;

	//Initialize SDL
	if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
	{
		printf( "SDL could not initialize! SDL_Error: %s\n", SDL_GetError() );
	}
	else
	{
		//Create window
		window = SDL_CreateWindow( "SDL Tutorial", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN );
		if( window == NULL )
		{
			printf( "Window could not be created! SDL_Error: %s\n", SDL_GetError() );
		}
		else
		{
			//Get window surface
			screenSurface = SDL_GetWindowSurface( window );

			//Fill the surface white
			SDL_FillRect( screenSurface, NULL, SDL_MapRGB( screenSurface->format, 0xFF, 0x00, 0xFF ) );
			
			//Update the surface
			SDL_UpdateWindowSurface( window );
            
            //Hack to get window to stay up
            SDL_Event e; bool quit = false; while( quit == false ){ while( SDL_PollEvent( &e ) ){ if( e.type == SDL_QUIT ) quit = true; } }
		}
	}

	//Destroy window
	SDL_DestroyWindow( window );

	//Quit SDL subsystems
	SDL_Quit();

	return 0;
}
