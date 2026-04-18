---
layout: post
title: Competing in eXp's Inaugural Hackathon
date: '2024-11-05 03:52:21 -0800'
slug: competing-in-exp-s-inaugural-hackathon
description: eXp Realty hosted their inaugural Hackathon in Miami on October 26, 2024.
  I competed among 60+ innovators using OpenAI's latest technology.
original_id: 166
image: "/assets/images/posts/competing-in-exp-s-inaugural-hackathon/expcon-miami-hackathon-2024.png"
cover: "/assets/images/posts/competing-in-exp-s-inaugural-hackathon/expcon-miami-hackathon-2024.png"
---

eXp Realty hosted their inaugural Hackathon in Miami on October 26, 2024. I competed among 60+ innovators using OpenAI's latest technology and eXp's specially prepared API. It was the first Hackathon I ever participated in, and I would be remiss if I didn't take part, being an eXp agent and proptech aficionado myself. The competition focused on solving key challenges in the real estate and brokerage space. Prizes consisted of $5,000 for first place, $1,000 for second, $500 for third, and a $1,000 Crowd Choice prize. The judging criteria was based on platform utilization, challenges solved, novelty and creativity of the idea, with participants given just 6 hours to ideate and develop a proof of concept.

I was set to arrive the night before the Hackathon, yet on the way to the Vancouver International Airport, I received last-minute notification that my flight was changed and I would be arriving the next morning. A mere 2 hours before the Hackathon was scheduled to start at 9:00AM sharp. Suffice to say, I didn't get a wink of sleep on the flight, and was running on fumes from the moment I arrived. Entering the conference room where the event was held, I immediately knew I was in for a challenge. There were many solo competitors, but mostly teams of veteran Hackathon assassins with full desktop monitor setups.

The challenges were announced at the event so everyone started on an even playing field, since solutions had to be built entirely on-site during the Hackathon. You were able to build a feature onto an existing piece of software, which was the path I decided to take, but only the feature would be considered for judging. Competitors had to solve 1 or more of the 9 challenges facing the real estate industry:

1. Increasing listing fees on international property portals.
2. New commission regulation requirements.
3. Difficulty in managing business while on the go.
4. Lead generation challenges.
5. Slim profit margins and high operational costs.
6. Overwhelming number of eXp programs and opportunities.
7. Slow market and affordability issues.
8. Increasing regulatory restrictions on cold lead outreach.
9. Difficulty tracking buyer referral outcomes.

I took on three challenges: managing business while on the go, lowering operational costs, and consolidating an overwhelming number of eXp programs. OpenAI gave competitors enterprise access to their newest o1-preview, o1-mini, gpt-4o realtime + audio language models, and eXp provided access to their RESO WebAPI. My tech stack was Rails 7, Hotwire, Stimulus, PostgreSQL, and Tailwind components for design. I also incorporated platforms such as Twilio, Mapbox, and SkySlope.

I tend to gravitate toward unsexy solutions in real estate as opposed to chasing shiny objects. With the advancements in technology, liberation of data, and plethora of new point solutions, the fundamentals still largely remain the same. Professionals want to reclaim more time, streamline operations, and lower the cost of customer acquisition. Customers want to work with someone they know like and trust, and don't care how much you know unless they know how much you care.

The solution that I built is embedded into an agent's workflow, enabling them to provide value at a higher level. It combines a portal, agent communication, document review, and transaction coordination in one seamless thread. First, the user inputs a prompt which is processed by the gpt-4o-mini model through Natural Language Processing (NLP). It then turns the result into an SQL statement, using a model that is trained on a database schema. The user can then make a request to the listing agent to see if the property is still available, and the Assistant API then performs a function call to send the message through Twilio. Documents such as strata docs or land titles can then be reviewed by uploading them to the Assistant's vector database.

As a final step, you can create a SkySlope transaction just as you would ask a virtual assistant to. Behind the scenes, the transaction requirements are satisfied with the property information from the MLS® including the listing agent, the documents that were reviewed, and the client information from the CRM. All in one multi-modal interface.

There was a qualifying round in which I pitched my product, and while the judge stated I should productize my solution and distribute it to fellow agents including herself, it didn't make the cut. The winner of the Hackathon was another eXp agent who's team built a referral bidding system, which is something I could use myself based on past experiences. Nobody knows the pain points as intimately as the practitioner, and to build technology around a process, you should understand that process really well. Overall, it was an amazing experience to be a part of the collective energy and evolution of real estate technology.
