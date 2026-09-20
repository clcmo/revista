% VIEW: só apresentação. Não lê arquivos nem toma decisões de conteúdo:
% consome as macros \Rev... e \Art... produzidas pelo ViewModel (lua/viewmodel.lua).
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{revista}[2026/09/19 Modelo de revista em LuaLaTeX (View)]
\LoadClass[10pt,a4paper]{scrartcl}

\RequirePackage{iftex}
\RequireLuaTeX
\RequirePackage[brazilian]{babel}
\RequirePackage{fontspec}
\setmainfont{TeX Gyre Pagella}
\setsansfont{TeX Gyre Heros}
\setmonofont{TeX Gyre Cursor}[Scale=MatchLowercase]
\RequirePackage[a4paper,inner=2cm,outer=2cm,top=2.4cm,bottom=2.4cm]{geometry}
\RequirePackage{multicol,xcolor,graphicx,etoolbox,microtype}
\RequirePackage{tikz}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage[headsepline=false]{scrlayer-scrpage}

% ---- Ponte com o ViewModel -------------------------------------------------
\directlua{vm = dofile("lua/viewmodel.lua")}
\newif\ifArtNovaSecao
\AtBeginDocument{%
  \directlua{vm.iniciar()}%
  \definecolor{revcor}{HTML}{\RevCor}%
  \hypersetup{pdftitle={\RevTitulo\space nº \RevNumero},pdfauthor={\RevTitulo}}%
}

% ---- Estilo ---------------------------------------------------------------
\setcounter{tocdepth}{2}
\addto\captionsbrazilian{\renewcommand*{\contentsname}{Nesta edição}}
\setkomafont{disposition}{\sffamily\bfseries}
\pagestyle{scrheadings}
\clearpairofpagestyles
\cfoot{\sffamily\footnotesize\color{revcor}\RevTitulo\ \textbullet\ nº\,\RevNumero\ \textbullet\ \pagemark}
\setlength{\columnsep}{1.4em}
\setlength{\parindent}{1.2em}
\setlength{\parskip}{0pt}
\setlength{\multicolsep}{6pt}

\newcommand{\intertitulo}[1]{\par\vspace{.7\baselineskip}%
  {\noindent\sffamily\bfseries\color{revcor}#1\par}\nobreak\vspace{.25\baselineskip}}
\newcommand{\subintertitulo}[1]{\par\vspace{.4\baselineskip}%
  {\noindent\sffamily\bfseries\small #1\par}\nobreak}
\newcommand{\separador}{\par\vspace{.3\baselineskip}\centerline{\color{revcor}\textbullet\ \textbullet\ \textbullet}\vspace{.3\baselineskip}\par}
\newenvironment{citacao}
  {\par\begin{list}{}{\setlength{\leftmargin}{1em}\setlength{\rightmargin}{0pt}\itshape\color{revcor}}\item\relax}
  {\end{list}\par}

% ---- Capa -----------------------------------------------------------------
\newcommand{\revistaCapa}{%
  \thispagestyle{empty}%
  \begin{tikzpicture}[remember picture,overlay]
    \fill[revcor] (current page.south west) rectangle (current page.north east);
    \ifdefempty{\RevCapaImagem}{%
      \foreach \i in {1,...,14}{%
        \pgfmathsetmacro{\op}{0.04+0.012*\i}%
        \draw[white,opacity=\op,line width=0.8pt]
          ([xshift=-2cm,yshift=\RevSemente cm]current page.south east) circle ({\i*1.3cm});%
      }%
    }{%
      \begin{scope}
        \clip (current page.south west) rectangle (current page.north east);
        \node[inner sep=0pt] at (current page.center)
          {\includegraphics[height=\paperheight]{\RevCapaImagem}};
      \end{scope}
      \fill[black,opacity=.38] (current page.south west) rectangle (current page.north east);
    }%
    \node[anchor=north west,text=white,inner sep=0pt] at ([xshift=2cm,yshift=-2.4cm]current page.north west)
      {\sffamily\bfseries\large\MakeUppercase{nº\,\RevNumero}\quad\textbullet\quad\RevData};
    \node[anchor=south west,text=white,inner sep=0pt,text width=15cm,align=left]
      at ([xshift=2cm,yshift=3.2cm]current page.south west)
      {{\sffamily\bfseries\fontsize{54}{58}\selectfont\RevTitulo\\[2.5ex]}%
       {\large\itshape\RevLema}};
    \node[anchor=north west,text=white,inner sep=0pt,text width=15cm,align=left]
      at ([xshift=2cm,yshift=-7.5cm]current page.north west)
      {{\sffamily\bfseries\small\MakeUppercase{\RevCapaSecao}\\[.8ex]}%
       {\sffamily\bfseries\fontsize{25}{29}\selectfont\RevCapaTitulo\\[.8ex]}%
       {\large\RevCapaChamada}};
  \end{tikzpicture}%
  \ifdefempty{\RevCapaCredito}{}{%
    \vfill{\color{white}\sffamily\tiny\RevCapaCredito}}%
  \clearpage}

% ---- Sumário --------------------------------------------------------------
\newcommand{\revistaSumario}{\tableofcontents\clearpage}

% ---- Artigo ---------------------------------------------------------------
\newcommand{\revistaArtigo}{%
  \clearpage\phantomsection
  \ifArtNovaSecao\ifdefempty{\ArtSecao}{}{\addcontentsline{toc}{section}{\ArtSecao}}\fi
  \addcontentsline{toc}{subsection}{\ArtTitulo}%
  {\noindent\sffamily\bfseries\small\color{revcor}\MakeUppercase{\ArtSecao}\par}%
  \vspace{.5ex}%
  {\raggedright\sffamily\bfseries\fontsize{28}{31}\selectfont\ArtTitulo\par}%
  \ifdefempty{\ArtResumo}{}{\vspace{1.2ex}{\raggedright\large\itshape\ArtResumo\par}}%
  \vspace{1.2ex}%
  {\sffamily\small\ifdefempty{\ArtAutor}{}{\textbf{\ArtAutor}\ \textbullet\ }%
   \ifdefempty{\ArtData}{}{\ArtData\ \textbullet\ }%
   \ArtLeitura\,min de leitura\par}%
  \ifdefempty{\ArtFonte}{}{\vspace{.3ex}{\sffamily\tiny\ArtFonte\ifdefempty{\ArtURL}{}{\space\textbullet\space\ArtURL}\par}}%
  \vspace{.4ex}{\color{revcor}\hrule height 1.2pt}\vspace{1.4ex}%
  \ifdefempty{\ArtImagem}{}{%
    \begin{center}
      \includegraphics[width=\textwidth]{\ArtImagem}\\[-.2ex]
      \ifdefempty{\ArtCredito}{}{{\sffamily\tiny\ArtCredito}}
    \end{center}\vspace{.6ex}}%
  \begin{multicols}{2}\ArtCorpo\end{multicols}}

% ---- Expediente / colofão ---------------------------------------------------
\newcommand{\revistaColofao}{%
  \clearpage\thispagestyle{empty}\vspace*{\fill}%
  {\sffamily\small\noindent{\bfseries\RevTitulo}\ \textbullet\ nº\,\RevNumero\ \textbullet\ \RevData\par
  \vspace{1ex}\RevExpediente\par}}

% ---- Edição completa ---------------------------------------------------------
\newcount\rev@i
\newcommand{\revistaEdicao}{%
  \revistaCapa
  \revistaSumario
  \rev@i=1
  \loop\ifnum\rev@i>\RevNumArtigos\else
    \directlua{vm.selecionar(\the\rev@i)}%
    \revistaArtigo
    \advance\rev@i by 1
  \repeat
  \revistaColofao}
