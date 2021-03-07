name: empty
layout: true
---
name: base
layout: true
template: empty
background-image: none
<div class="slide-footer">@sudo_bmitch</div>
---
name: ttitle
layout: true
template: empty
class: center, middle
background-image: url(img/containers_bg.png)
background-size: cover
---
name: inverse
layout: true
template: base
class: center, middle, inverse
background-image: none
---
name: impact
layout: true
template: base
class: center, middle, impact
background-image: url(img/containers_bg.png)
background-size: cover
---
name: picture
layout: true
template: base
class: center, middle
background-image: none
---
name: terminal
layout: true
template: base
class: center, middle, terminal
background-image: none
---
name: default
layout: true
template: base
background-image: url(img/containers_bg.png)
background-size: cover
---
layout: false
template: default
name: agenda

# Agenda

.left-column[
- [topic 1](#topic-1)
- [topic 2](#topic-2)
- [topic 3](#topic-3)
- [topic 4](#topic-4)
]
.right-column[
- [topic 5](#topic-5)
- [topic 6](#topic-6)
- [topic 7](#topic-7)
- [topic 8](#topic-8)
]

---
layout: false
name: ttitle
template: ttitle

# Tips and Tricks<br>From A Docker Captain

.left-column[
.pic-circle-70[![Brandon Mitchell](img/bmitch.jpg)]
]
.right-column[.v-align-mid[.no-bullets[
<br>
- Brandon Mitchell
- Twitter: @sudo_bmitch
- GitHub: sudo-bmitch
]]]
???
- My twitter and github handles are what any self respecting sysadmin does
  when you get a permission denied error on your favorite username.
- This presentation is on github and I'll have a link to it at the end,
  I'll be going fast so don't panic if you miss a slide.
---
template: default

```no-highlight
$ whoami
- Solutions Architect @ BoxBoat
- Docker Captain
- Frequenter of StackOverflow
```

.align-center[
.pic-30[![BoxBoat](img/boxboat-logo-color.png)]
.pic-30[![Docker Captain](img/docker-captain.png)]
.pic-30[![StackOverflow](img/stackoverflow-logo.png)]
]

???

---

template: inverse

# Inverse slide

???

- Discussion content

---

# Normal Slide

- Bullets

---

class: center

.pic-80[![Alt Text](img/image.png)]

---

class: center

.pic-80[.pic-rounded-10[![Alt Text](img/image.png)]]

---

exclude: true

# Hidden Slide

- Bullets

---

# Code page

```no-highlight
code
goes
here
```

---

template: terminal
name: topic-2
class: center

<asciinema-player src="file.cast" cols=100 rows=26 preload=true font-size=16></asciinema-player>

---
