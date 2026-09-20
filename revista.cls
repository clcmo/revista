% VIEW: só apresentação. Não lê arquivos nem toma decisões de conteúdo:
% consome as macros \Rev... e \Art... produzidas pelo ViewModel (lua/viewmodel.lua).
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{revista}[2026/09/19 Modelo de revista em LuaLaTeX (View)]
\LoadClass[14pt,a4paper]{scrartcl}

\RequirePackage{iftex}
\RequireLuaTeX
\RequirePackage[brazilian]{babel}
\RequirePackage{fontspec}
\setmainfont{TeX Gyre Heros}
\setsansfont{TeX Gyre Heros}
\setmonofont{TeX Gyre Cursor}[Scale=MatchLowercase]
\RequirePackage[a4paper,inner=2cm,outer=2cm,top=2.4cm,bottom=2.4cm]{geometry}
\RequirePackage{multicol,xcolor,graphicx,etoolbox,microtype}
\RequirePackage{tikz}
\RequirePackage[hidelinks]{hyperref}
\RequirePackage[headsepline=false]{scrlayer-scrpage}

% ---- Ponte com o ViewModel -------------------------------------------------
\directlua{vm = dofile("lua/viewmodel.lua")}
\AtBeginDocument{%
  \directlua{vm.iniciar()}%
  \definecolor{revcor}{HTML}{\RevCor}%
  \hypersetup{pdftitle={\RevTitulo\space nº \RevNumero},pdfauthor={\RevTitulo}}%
}

% ---- Estilo ---------------------------------------------------------------
\setcounter{tocdepth}{2}
\addto\captionsbrazilian{\renewcommand*{\contentsname}{Nesta edição}}
\setkomafont{disposition}{\sffamily\bfseries}
\linespread{1.5}\selectfont
\pagestyle{scrheadings}
\clearpairofpagestyles
\cfoot{\sffamily\footnotesize\color{revcor}\RevTitulo\ \textbullet\ nº\,\RevNumero\ \textbullet\ \pagemark}
\setlength{\columnsep}{1.4em}
\setlength{\parindent}{0pt}
\setlength{\parskip}{.45em}
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
    \ifdefempty{\RevCapaMolde}{}{%
      \begin{scope}
        \clip (current page.south west) rectangle (current page.north east);
        \node[inner sep=0pt] at (current page.center)
          {\includegraphics[height=\paperheight]{\RevCapaMolde}};
      \end{scope}}
    \node[anchor=south east,text=white,inner sep=0pt,align=right] at ([xshift=-2cm,yshift=2cm]current page.south east)
      {\sffamily\bfseries\large\MakeUppercase{nº\,\RevNumero}\\[-.2ex]\RevData};
    \ifdefempty{\RevCapaMolde}{%
      \node[anchor=north west,text=white,inner sep=0pt,text width=15cm,align=left]
        at ([xshift=2cm,yshift=-4.2cm]current page.north west)
        {\sffamily\bfseries\fontsize{38}{42}\selectfont\RevTitulo};
    }{}%
    \node[anchor=south west,text=white,inner sep=0pt,text width=15cm,align=left]
      at ([xshift=2cm,yshift=3.2cm]current page.south west)
      {\large\itshape\RevLema};
    \node[anchor=north west,text=white,inner sep=0pt,text width=15cm,align=left]
      at ([xshift=2cm,yshift=-11cm]current page.north west)
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
% Decisões de layout ficam aqui (View): colunas, página de abertura, destaque em 2 páginas.
\newcommand{\revcolunasmin}{450}   % textos abaixo disso (palavras) saem em coluna única
\newsavebox{\rev@box}
\newsavebox{\rev@meta}
\newlength{\rev@w}
\newlength{\rev@h}
\newlength{\rev@ah}

% Imagem que PREENCHE uma caixa #1 x #2 (corta as sobras, sem deformar).
\newcommand{\imagemPreencher}[3]{%
  \setlength{\rev@w}{#1}\setlength{\rev@h}{#2}%
  \sbox{\rev@box}{\includegraphics[width=\rev@w]{#3}}%
  \ifdim\ht\rev@box<\rev@h\sbox{\rev@box}{\includegraphics[height=\rev@h]{#3}}\fi
  \begin{tikzpicture}
    \clip (0,0) rectangle (\rev@w,\rev@h);
    \node[inner sep=0pt,anchor=center] at (0.5\rev@w,0.5\rev@h) {\usebox{\rev@box}};
  \end{tikzpicture}}

% Corpo do texto: 1 ou 2 colunas conforme o tamanho.
\newcommand{\revistaCorpo}{%
  \ifnum\ArtPalavras<\revcolunasmin\relax\ArtCorpo
  \else\begin{multicols}{2}\ArtCorpo\end{multicols}\fi}

% Metadados da publicação, em blocos reutilizáveis.
\newcommand{\revistaSecao}{%
  {\noindent\sffamily\bfseries\small\color{revcor}\MakeUppercase{\ArtSecao}\par}}
\newcommand{\revistaTitulo}{%
  {\raggedright\hyphenpenalty=10000 \exhyphenpenalty=10000 \sffamily\bfseries\fontsize{26}{29}\selectfont\ArtTitulo\par}}
\newcommand{\revistaResumo}{%
  \ifdefempty{\ArtResumo}{}{\vspace{1.2ex}{\raggedright\large\itshape\ArtResumo\par}}}
\newcommand{\revistaFicha}{%
  \vspace{1.2ex}%
  {\sffamily\small\ifdefempty{\ArtAutor}{}{\textbf{\ArtAutor}\ \textbullet\ }%
   \ifdefempty{\ArtData}{}{\ArtData\ \textbullet\ }%
   \ArtLeitura\,min de leitura\par}%
  \ifdefempty{\ArtFonte}{}{\vspace{.3ex}{\raggedright\sffamily\scriptsize\ArtFonte\ifdefempty{\ArtURL}{}{\space\textbullet\space\ArtURL}\par}}%
  \vspace{.4ex}{\color{revcor}\hrule height 1.2pt}\vspace{1.4ex}}
\newcommand{\revistaCabecalho}{\revistaSecao\vspace{.5ex}\revistaTitulo\revistaResumo\revistaFicha}

% (a) Sem imagem: cabeçalho e texto começam juntos.
\newcommand{\revistaArtigoSemImagem}{\revistaCabecalho\revistaCorpo}

% (b) Com imagem: UMA página de abertura = metadados + imagem; o texto começa na seguinte.
\newcommand{\revistaAberturaPagina}{%
  \sbox{\rev@meta}{\begin{minipage}{\textwidth}\revistaCabecalho\end{minipage}}%
  \setlength{\rev@ah}{\textheight}%
  \addtolength{\rev@ah}{-\ht\rev@meta}\addtolength{\rev@ah}{-\dp\rev@meta}%
  \addtolength{\rev@ah}{-3\baselineskip}%  respiro + linha de crédito
  \ifdim\rev@ah>.55\textheight\setlength{\rev@ah}{.55\textheight}\fi
  \ifdim\rev@ah<5cm\setlength{\rev@ah}{5cm}\fi
  \noindent\usebox{\rev@meta}\par\vspace{.5ex}%
  \noindent\imagemPreencher{\textwidth}{\rev@ah}{\ArtImagem}\par
  \ifdefempty{\ArtCredito}{}{\vspace{.4ex}{\sffamily\tiny\ArtCredito}\par}%
  \clearpage
  \revistaCorpo}

% (c) Destaque: 2 páginas. Pág. 1 = imagem em página inteira com título e dados sobre ela;
%     pág. 2 = resumo, ficha completa (autor, data, fonte, link) e início do texto.
\newcommand{\revistaAberturaDestaque}{%
  \thispagestyle{empty}%
  \begin{tikzpicture}[remember picture,overlay]
    \node[anchor=south west,inner sep=0pt] at (current page.south west)
      {\imagemPreencher{\paperwidth}{\paperheight}{\ArtImagem}};
    \fill[black,opacity=.22] (current page.south west) rectangle ([yshift=.62\paperheight]current page.south east);
    \fill[black,opacity=.22] (current page.south west) rectangle ([yshift=.46\paperheight]current page.south east);
    \fill[black,opacity=.22] (current page.south west) rectangle ([yshift=.32\paperheight]current page.south east);
    \node[anchor=south west,text=white,inner sep=0pt,text width=\textwidth,align=left]
      at ([xshift=2cm,yshift=2.4cm]current page.south west)
      {{\sffamily\bfseries\small\MakeUppercase{\ArtSecao}\\[1.2ex]}%
       {\hyphenpenalty=10000 \exhyphenpenalty=10000 \sffamily\bfseries\fontsize{32}{36}\selectfont\ArtTitulo\\[1.6ex]}%
       {\sffamily\small\ifdefempty{\ArtAutor}{}{\textbf{\ArtAutor}\ \textbullet\ }\ArtData}};
  \end{tikzpicture}%
  \ifdefempty{\ArtCredito}{}{\vfill{\color{white}\sffamily\tiny\ArtCredito}}%
  \clearpage
  \revistaSecao\vspace{.8ex}%
  \ifdefempty{\ArtResumo}{}{{\raggedright\LARGE\itshape\ArtResumo\par}}%
  \revistaFicha
  \revistaCorpo}

\newcommand{\revistaArtigo}{%
  \clearpage\phantomsection
  \ifnum\ArtNovaSecao=1 \ifdefempty{\ArtSecao}{}{\addcontentsline{toc}{section}{\ArtSecao}}\fi
  \addcontentsline{toc}{subsection}{\ArtTitulo}%
  \ifdefempty{\ArtImagem}%
    {\revistaArtigoSemImagem}%
    {\ifnum\ArtDestaque=1 \revistaAberturaDestaque\else\revistaAberturaPagina\fi}}

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
