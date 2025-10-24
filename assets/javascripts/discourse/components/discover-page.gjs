import avatar from "discourse/helpers/avatar";

<template>
  <div class="frndr-discover">
    <h1>Discover Friends</h1>

    {{#if @model.matches.length}}
      <div class="frndr-matches">
        {{#each @model.matches as |match|}}
          <div class="frndr-match-card">
            <div class="frndr-match-avatar">
              {{avatar match size="huge"}}
            </div>
            <div class="frndr-match-info">
              <h3>{{match.username}}</h3>
              {{#if match.name}}
                <p class="frndr-match-name">{{match.name}}</p>
              {{/if}}
              <div class="frndr-compatibility">
                <span
                  class="frndr-compatibility-score"
                >{{match.compatibility}}%</span>
                <span class="frndr-compatibility-label">compatible</span>
              </div>
            </div>
            <div class="frndr-match-actions">
              <a href="/u/{{match.username}}" class="btn btn-primary">
                View Profile
              </a>
            </div>
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="frndr-no-matches">
        <p>No matches found yet. Make sure you've filled out your profile
          questions!</p>
      </div>
    {{/if}}
  </div>
</template>
