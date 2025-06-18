---
title: Contact
authors:
  - Munir
status: true
visibility: true
slug: contact
robots: index, follow
published: false
custom_field:
  custom_key: custom_value
hide:
  - navigation
  - toc
  - path
  - footer
  - header
  - git-revision-date
---

<style>
  html[data-md-color-scheme="default"] .contact-form {
    background-color: #ffffff;
    color: #000000;
    border: 1px solid #ccc;
  }

  html[data-md-color-scheme="slate"] .contact-form {
    background-color: #1e1e1e;
    color: #ffffff;
    border: 1px solid #444;
  }

  .contact-form input,
  .contact-form textarea {
    width: 100%;
    padding: 8px;
    margin-bottom: 1rem;
    border-radius: 4px;
    border: 1px solid #bbb;
  }

  .contact-form button {
    background-color: #007BFF;
    color: white;
    padding: 10px 20px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }
</style>

<div style="display: flex; justify-content: center; margin-top: 2rem;">
  <form action="https://formspree.io/f/xkgraakd" method="POST" class="contact-form" style="width: 100%; max-width: 500px; padding: 1rem; border-radius: 8px;">

    <label for="name">Name:</label><br>
    <input type="text" name="name" required title="Please enter your full name"><br>

    <label for="email">E-Mail:</label><br>
    <input type="email" name="email" required title="Enter a valid email so I can reply"><br>

    <label for="message">Message:</label><br>
    <textarea name="message" rows="5" required title="Write your message or question here"></textarea><br>

    <div style="text-align: center;">
      <button type="submit" title="Click to send your message">
        Submit
      </button>
    </div>

  </form>
</div>
