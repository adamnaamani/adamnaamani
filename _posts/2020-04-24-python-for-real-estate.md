---
layout: post
title: Python for Real Estate
date: '2020-04-24 22:28:30 -0700'
slug: python-for-real-estate
description: Learning Python is important to being a well-rounded engineer, particularly
  when it comes to the data-intensive industry of Real Estate.
original_id: 28
image: "/assets/images/posts/python-for-real-estate/python-real-estate.jpg"
cover: "/assets/images/posts/python-for-real-estate/python-real-estate.jpg"
---

> "Maintainable code is more important than clever code." – Guido van Rossum, creator of Python

I've been spending time taking online courses, specifically in the areas of Data Science, Machine Learning, and [Python](https://www.python.org). My go-to platform right now is [Coursera](https://www.coursera.org)—I managed to complete three university-grade courses within a week for free. As long as you stay within the one-week trial period, you don't incur any fees.

Over the last 2+ years, I've been fully immersed in [Ruby on Rails](https://rubyonrails.org), both for [work and personal projects](https://adamnaamani.com/year-of-the-rat/). When building large-scale applications, Rails' convention over configuration is ideal. Ruby has an incredibly expressive, human-readable syntax, and is truly a joy to program alongside a team.

Learning Python seemed to be the natural evolution of being a well-rounded engineer. When it comes to the data-intensive industry of real estate, it is the predominant language with an extensive collection of data crunching libraries. [Zillow](http://zillow.com), [HouseCanary](https://www.housecanary.com), and [Opendoor](http://opendoor.com), all use Python as their preferred dynamic language, as machine learning and predictive analytics are central to their business models.

So what is it that makes Python such a powerful language to analyze real estate data? A simple demonstration can show how little overhead is required to extract insights from large datasets.

I've put together a repository of my learnings on [Github](https://github.com/adamnaamani/handbook):

- [Python](https://github.com/adamnaamani/handbook/blob/master/pages/python.md)
- [Machine Learning](https://github.com/adamnaamani/handbook/blob/master/pages/machine-learning.md)

**Libraries**

Before diving into a practical demonstration of Python, let's first look at the libraries that make it incredibly easy to manipulate data:

**NumPy**

[NumPy](https://numpy.org/) is the fundamental package for scientific computing with Python. It contains among other things:

- A powerful N-dimensional array object.
- Sophisticated (broadcasting) functions.
- Useful linear algebra, Fourier transform, and random number capabilities.

**Pandas**

[pandas](https://pandas.pydata.org/) is a fast, powerful, flexible and easy-to-use open-source data analysis and manipulation tool, built on top of the Python programming language.

**Scikit-learn**

[scikit-learn](https://scikit-learn.org/) provides simple and efficient tools for predictive data analysis. Built on NumPy, SciPy, and matplotlib.

**Keras**

[Keras](https://keras.io/) is a high-level neural networks API, written in Python and capable of running on top of TensorFlow, CNTK, or Theano. It was developed with a focus on enabling fast experimentation.

> Keras (κέρας) means horn in Greek. It is a reference to a literary image from ancient Greek and Latin literature, first found in the Odyssey, where dream spirits (Oneiroi, singular Oneiros) are divided between those who deceive men with false visions, who arrive to Earth through a gate of ivory, and those who announce a future that will come to pass, who arrive through a gate of horn. It's a play on the words κέρας (horn) / κραίνω (fulfill), and ἐλέφας (ivory) / ἐλεφαίρομαι (deceive).

**matplotlib**

[matplotlib](https://matplotlib.org/) is a comprehensive library for creating static, animated, and interactive visualizations in Python.

**TensorFlow**

[TensorFlow](https://www.tensorflow.org/) is an end-to-end open-source platform for machine learning. It has a comprehensive, flexible ecosystem of tools, libraries and community resources that lets researchers push the state-of-the-art in ML and developers easily build and deploy ML-powered applications.

**Analyzing Data**

To bring it all together, the following is a simple example that was put together in a [Jupyter Notebook](https://jupyter.org), which fetches the property tax dataset from the City of Vancouver's open data API. In the terminal, install jupyterlab and notebook to get started:

```bash
pip3 install jupyterlab
pip3 install notebook
jupyter notebook
```

**1. Fetch the dataset**

The [requests](https://requests.readthedocs.io/en/master/) library is the preferred way to send HTTP/1.1 requests with ease, also known as **HTTP for Humans™**. We'll import the [json](https://docs.python.org/3/library/json.html) module, as it is the de facto standard for data interchange, as well as the aforementioned numpy and pandas:

```python
import requests
import json
import numpy as np
import pandas as pd

url = ("https://opendata.vancouver.ca/<endpoint>")
payload = {
  'rows': -1,
  'timezone': 'UTC',
  'pretty': 'true',
  'where': "report_year=2020"
}
response = requests.get(url, params=payload)
records = response.json()
```

**2. Explore the dataset**

Now we can see at a high-level what data is in the response:

```python
type(records)
# list

len(records)
# 214597
```

**3. Analyze a record**

The first order is to analyze a single record and its key/value pairs. This will allow us to visualize the structure in its original state so that we can perform the necessary modifications:

```python
print(json.dumps(records[0], indent=2))
```

```json
{
  "tax_assessment_year": "2020",
  "street_name": "15TH AVE W",
  "pid": "011-997-851",
  "property_postal_code": "V6K 2Y9",
  "legal_type": "LAND",
  "zone_name": "RS-5",
  "folio": "688078030000",
  "lot": "20",
  "previous_improvement_value": 78800,
  "land_coordinate": "68807803",
  "narrative_legal_line4": null,
  "narrative_legal_line5": null,
  "narrative_legal_line2": "STRICT LOT 526 NEW WESTMINSTER",
  "plan": "VAP3944",
  "narrative_legal_line1": "LOT 20 BLOCK 442 PLAN VAP3944 DI",
  "previous_land_value": 2828000,
  "current_improvement_value": 109000,
  "from_civic_number": null,
  "year_built": "1930",
  "report_year": "2020",
  "neighbourhood_code": "002",
  "zone_category": "One Family Dwelling",
  "big_improvement_year": "1960",
  "tax_levy": null,
  "to_civic_number": "2395",
  "current_land_value": 2494000,
  "district_lot": "526",
  "block": "442",
  "narrative_legal_line3": null
}
```

**4. Clean the dataset**

Real estate data will always require cleaning. If you think about the number of parties associated with a property's lifecycle: realtors, appraisers, lenders, government, etc. there are bound to be errors and omissions in data entry somewhere along the line which we want to account for.

For sake of brevity, we'll look at one attribute we may want to ensure is in a suitable format for analysis or persistence to a database, in this case, casting the year\_built to an integer if it exists:

```python
dataset = []
for record in records:
  d = dict(record)
  for field in ['year_built']:
    d[field] = int(d[field]) if d[field] else None
  dataset.append(d)
```

**5. Create the DataFrame**

With data in a consistent format, the next step is to create the pandas DataFrame and drop rows that don't contain required fields. Jupyter also makes it easy to visualize the results in tabular format, right in the notebook:

```python
df = pd.DataFrame(dataset)
df = df[~df.isin([0, 1])]
df = df.dropna(subset=[
  'tax_assessment_year',
  'current_improvement_value',
  'current_land_value',
  'year_built',
])

# First 10 rows
df.head(n=10)

# Columns
df.columns

# Single attribute
df.street_name

# Unlabeled array
df.to_numpy()

# Sort values
df.sort_values(by='current_land_value')
```

**6. Identify statistics**

Pandas has a wealth of built-in statistical methods for DataFrames. You can even run a single method to get basic stats on numerical columns, and why it's important to first ensure the data is in the right format. The .describe() method returns a new DataFrame with the number of rows, mean, standard deviation, minimum, maximum, and quartiles of the columns:

```python
# Create currency converter function
def convert_to_currency(num):
  return '${:,.2f}'.format(num)

# Average land value
convert_to_currency(df.current_land_value.mean())
# $1,604,841

# Average improvement value
convert_to_currency(df.current_improvement_value.mean())
# $415,351

# Highest land value
convert_to_currency(max(sorted(df.current_land_value)))
# $2,759,584,000

# Highest improvement value
convert_to_currency(max(sorted(df.current_improvement_value)))
# $693,426,000
```

**7. Create visualizations**

No holistic real estate analysis would be complete without charts. They help us quickly identify trends, outliers, and relationships between variables.

```python
import matplotlib.pyplot as plt

zone_counts = df.zone_category.value_counts()
zones = zone_counts.keys().tolist()
zone_list = zone_counts.tolist()

fig = plt.figure(figsize=(20, 5))
ax = fig.add_axes([0, 0, 1, 1])
ax.bar(zones, zone_counts)

plt.title("Property Tax Zones", fontsize=20)
plt.xlabel("Zone Category", fontsize=20)
plt.ylabel("Number of Properties", fontsize=20)
plt.xticks(rotation=45, ha='right', fontsize=15)
plt.show()

x = df.year_built
y = df.current_land_value + df.current_improvement_value

plt.figure(figsize=(20, 5))
plt.title("Assessed Values", fontsize=20)
plt.xlabel("Year", fontsize=20)
plt.ylabel("Price", fontsize=20)
plt.xticks(rotation=45, ha='right', fontsize=15)
plt.scatter(x, y, alpha=0.3, cmap='viridis')
```

**Looking Forward**

This is only scratching the surface of how powerful the Python programming language is in applying it to real estate analysis. Given the complexity of MLS and property data, it simply enables a much more efficient process. Getting a taste of the capabilities that Python provides has me looking forward to diving deeper into the more advanced concepts. Neural networks, regression models, and data visualization are integral components of predicting house prices and are vital tools as industries move forward in an increasingly virtual business environment.

_Photo by_ [_David Clode_](https://unsplash.com/@davidclode?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) _on_ [_Unsplash_](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
