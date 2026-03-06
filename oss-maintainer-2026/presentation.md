# Life of an OSS Developer

<div class="container">
<div class="col"><p data-markdown>

GWU OSCon 2026<br>
Brandon Mitchell<br>
2026-03-23

</p></div>

<div class="col" data-markdown>
<img src="../_shared/img/bmitch.jpg" class="pic-circle-title" alt="Photo"/>
</div>
</div>

Note:

- How many people here want to contribute to OSS projects?
- And how many people here maintain a popular OSS project, with >1000 users or stars?

------

## whoami

```shell
$ whoami
- Brandon Mitchell
- OSS Developer
- OCI Maintainer, regclient, Docker Captain
- Mastodon, Slack, Hacker News, Matrix, StackOverflow
```

Note:

- I'm semi-retired, at some point I'll take up some side projects
- My free time is spent as an open source developer
- My OSS focus is on the Open Container Initiative (OCI)
  - Under the Linux Foundation (LF)
  - That's the specification and some core projects used by Docker and Kubernetes
  - I'm a maintainer there, on the TOB, and my own side projects like regclient and olareg focus on it
  - I'm also a Docker Captain
- On the socials, I can be found on Mastodon, various Slacks, Hacker News, I'm trying Matrix, and I occasionally answer questions on StackOverflow
- When I'm not doing any of this, I like to go sailing on the Bay or take a bike ride on the W&OD

---

## Walk In Their Shoes

Note:

- I have a philosophy that if I were to have the same experiences and given the same opportunities of another, I would make their same choices.
  - So rather than discouraging a behavior, I think it's important to have an understanding of different groups.
- When I attended this conference last year, it was eye opening to me to see how OSS was perceived by the academic community
  - There's a lot of focus on research, grants, and an on-ramp to employment
- The goal of this talk is to share the experience of what it's like for a non-academic OSS maintainer.

---

## Software Is Unique

- Nearly free to copy
- One developer can scale to lots of users <!-- .element: class="fragment" data-fragment-index="2" -->
- Open source software increases potential users <!-- .element: class="fragment" data-fragment-index="3" -->
- ... but it also adds a poll of contributors <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- Unlike manufacturing, and lots of service jobs, software is easily replicated.
  - Paralleled by the music and movie industries.
- The ability for a developer to scale to lots of users is probably why we are paid so well.
- Open source adds more potential users, but it also adds a poll of contributors.

------

## I Want To Contribute

- I would like to contribute to your project, would someone guide me through the process?
- Please assign this issue to me
- I'm running a survey for my class
- Here's the fix to my problem that an LLM generated
- Please merge this pull request
- Why isn't there a response to all these requests?

Note:

- Maybe once a week, I see someone asking to contribute to OSS in what I'd describe as a counter-productive way.
- The focus of the maintainer is on delivering a useful project to the community.
- While the focus from these requests is often not focused on the community, rather they want some personal gain.
- These are all requests to do unpaid work.

------

## Everyone Is Tired

![Hacks4pancakes pushing back on interview requests](img/hacks4pancakes-interviews.png) <!-- .element: height="580" -->

Note:

- This comes from the security side, but we see it all over.
- I'd like to appreciate that this is not a critique/request for the students, but of the faculty.

---

## Types of OSS Maintainer

- Company supported project
- Peripheral tool
- Personal side project <!-- .element: class="fragment" data-fragment-index="2" -->
- Retired <!-- .element: class="fragment" data-fragment-index="2" -->
- <!-- .element: class="fragment" data-fragment-index="3" -->
  ~Business model~ <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- Who's receiving those requests?
- A few companies will pay to have OSS developed for their core product
  - Often the employees are the maintainers, and are focused on the company rather than the community
  - Accepted changes are often based on whether it will drive more adoption of paid offerings
- Some companies sponsor OSS of what I call peripheral tools, outside of their core business
  - E.g. a video streaming company releasing their monitoring tool
- A good number of OSS maintainers are not paid, it's either a side project outside of work, or they are retired/unemployed/student
- Beware of what I call the "Silicon Valley venture capital business model".
  - They use OSS to capture the market, and then rug-pull...
  - Changing the license and start charging for what used to be free.
  - Cory Doctorow would call this "Enshitification".

------

## Maintainers Count

![Over 4M NPM projects with 1 maintainer](img/1-maintainer-npm.png) <!-- .element: height="500" -->

<small>Source: <https://opensourcesecurity.io/2025/08-oss-one-person/></small>

Note:

- You likely have an expectation of OSS maintainers from large projects, those are the exception
- This is a chart of NPM maintainers per project
  - The left axis is the number of projects
  - The bottom axis is the number of maintainers
- Over 4 million projects have a single maintainer
- This is with only 900,000 NPM maintainers
  - Each NPM maintainer is, on average, managing more than 4 projects

---

## What Do Maintainers Do?

- Code
- Build process <!-- .element: class="fragment" data-fragment-index="2" -->
- Tests <!-- .element: class="fragment" data-fragment-index="2" -->
- CI and Artifacts <!-- .element: class="fragment" data-fragment-index="3" -->
- Tagging and Releases <!-- .element: class="fragment" data-fragment-index="3" -->
- Dependency Updates <!-- .element: class="fragment" data-fragment-index="4" -->
- Security Fixes <!-- .element: class="fragment" data-fragment-index="5" -->

Note:

- Coders want to code, specializing in their language and tools.
- When you release that app to the public you also need:
  - A process to build it, tests, versioned releases, generating artifacts
- Mature projects the need:
  - Maintained dependencies (often a majority of the commits)
  - Handling security reports and releasing fixes
- Compare what the developer wanted to do (code) vs what is expected, this is a lot of added overhead.
  - This isn't just OSS, the DevOps movement resulted in developers doing more in most orgs.

------

## Managing Contributions

- Contributor Policy
- "Do I want to maintain this?" <!-- .element: class="fragment" data-fragment-index="2" -->
- "Yes" is forever, "No" is temporary <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- But as an OSS maintainer, we may have external contributors.
- Often that's just requests for features or bug reports.
- When accepting change requests, hopefully the maintainer made a contributor policy.
  - This describes if and how they accept contributions.
  - Often it will guide the contributor with the development workflow to build, test, and verify the change before submitting it.
- Accepting a contribution is a commitment.
  - It's not just "is this good enough to merge?"
  - The maintainer is asking "am I willing to maintain this?"
- Maintainers that have reached their capacity will frequently ignore requests, or say "no".
  - They can later change their mind from "no to yes", but they can't easily go from "yes to no" without burning the community.

------

## Building a Community

- Identify the repeat contributors
- What is safe to delegate? Who can you trust? <!-- .element: class="fragment" data-fragment-index="2" -->
- Solo maintainers are the vast majority <!-- .element: class="fragment" data-fragment-index="3" -->

Note:

- So why not add more maintainers, spread that workload?
  - To start, you need to find repeat contributors, and most of what we see are one-off requests.
- Next, you need to trust that contributor.
  - There are malicious actors trying to take over existing projects to spread malware and backdoors (see the xz vulnerability).
  - And that contributor needs to be willing to take on more responsibility.
- For most projects, after an initial startup, maintainers leave at a faster pace than they are added.
  - For a significant majority, the project never expands beyond a single maintainer.

---

## Why Maintain OSS?

- Public recognition
- Resume
- Scratch an itch <!-- .element: class="fragment" data-fragment-index="2" -->
- Create alternative <!-- .element: class="fragment" data-fragment-index="2" -->
- Giving back <!-- .element: class="fragment" data-fragment-index="2" -->

Note:

- So now that I've done such a good job selling this, why would anyone want to do it?
- Some are looking for public recognition or resume material.
  - That's likely a lot of people here. You want the GitHub history and public activity to get a job.
  - If you build a project for a resume, even if you abandon it later, that's a net positive.
  - If you perform a drive-by PR, frequently that creates more work for the maintainers than if they made the change.
- Many maintainers are scratching itches, building something they couldn't find elsewhere
  - Disposable AI projects are eating into this market
- Sometimes the alternatives have issues, paid, wrong license, wrong design.
- And there are those that do it as a community service after consuming OSS for much of their career (me).
  - The fear that OSS is full of older people doesn't scare me.
  - They've learned over career, seeing the problems and existing tools, and create solutions without a profit motive (rug pull).
- However if we do want to get more people into OSS earlier, we need to work on funding maintainers, because it is rarely a good business model.

---

# Thank You

<div class="container">
<div class="col"><p data-markdown>

![Presentations QR Link](../_shared/img/github-qr.png)

</div>
<div class="col"><p data-markdown>

- Brandon Mitchell
- GitHub: sudo-bmitch
- Mastodon: fosstodon.org/@bmitch

</div>
</div>

github.com/sudo-bmitch/presentations

Note:

- These slides are also available on my GitHub repo.

<!-- markdownlint-disable-file MD025 -->
<!-- markdownlint-disable-file MD034 -->
<!-- markdownlint-disable-file MD033 -->
<!-- markdownlint-disable-file MD035 -->
