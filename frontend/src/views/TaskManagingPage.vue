<template>
  <v-content><v-container grid-list-md><v-layout row wrap>
    <v-flex xs6>
      <h2>User: {{staffmember.givenName}} {{staffmember.name}}</h2>
    </v-flex>
    <v-flex xs12>
      <v-expansion-panel expand>
        <v-expansion-panel-content v-for="pg in tasks.projectGroup" :key="pg.key">         
          <div slot="header">
            <div class="caption">Project Group</div>
            <div>{{pg._title}}</div>
          </div>
          <v-expansion-panel expand inset>
            <v-expansion-panel-content v-for="p in pg.project" :key="p.key">
              <div slot="header">
                <v-container fluid><v-layout row wrap>
                  <v-flex>
                    <div class="caption">Project</div>
                    <div>{{p._title}}</div>
                  </v-flex>
                  <v-flex>
                    <div class="text-xs-right">
                      <v-chip v-for="m in p.member">{{m._staffmemberId}}</v-chip>
                    </div>
                  </v-flex>
                </v-layout></v-container>
              </div>
              <v-expansion-panel expand inset>
                <v-expansion-panel-content v-for="tg in p.taskGroup" :key="tg.key">
                  <div slot="header">
                    <div class="caption">Task Group</div>
                    <div>{{tg._title}}</div>
                  </div>
                  <v-expansion-panel-content v-for="t in tg.task" :key="t.key">
                    <div slot="header">
                      <v-container fluid><v-layout row wrap>
                        <v-flex>
                          <div class="caption">Task</div>
                          <div>{{t._title}}</div>
                        </v-flex>
                        <v-flex>
                          <div class="text-xs-right">
                            <v-chip v-for="m in t.member">{{m._staffmemberId}}</v-chip>
                          </div>
                        </v-flex>
                      </v-layout></v-container>
                    </div>
                  </v-expansion-panel-content>
                </v-expansion-panel-content>
              </v-expansion-panel>
              <v-expansion-panel expand inset>
                <v-expansion-panel-content v-for="t in p.task" :key="t.key">
                  <div slot="header">
                    <v-container fluid><v-layout row wrap>
                      <v-flex>
                        <div class="caption">Task</div>
                        <div>{{t._title}}</div>
                      </v-flex>
                      <v-flex>
                        <div class="text-xs-right">
                          <v-chip v-for="m in t.member">{{m._staffmemberId}}</v-chip>
                        </div>
                      </v-flex>
                    </v-layout></v-container>
                  </div>
                </v-expansion-panel-content>
              </v-expansion-panel>
            </v-expansion-panel-content>
          </v-expansion-panel>
        </v-expansion-panel-content>
      </v-expansion-panel>
    </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  
  const x2jsTasks = new X2JS({
    arrayAccessFormPaths : [
      /.+.projectGroup/,
      /.+.project/,
      /.+.member/,
      /.+.taskGroup/,
      /.+.task/
    ]
  });
  
  export default Vue.component('task-managing-page', {
    mixins: [pageMixin],
    data: function() {
      return {
        tasks: {
        }
      };
    },
    created: function () {
      this.loadData();
    },
    methods: {
      loadData: function() {
        console.log("loadData")
        const self = this
        self.server.get('../api/tasks/').then(function(taskResponse) {
          console.log("tasks:")
          console.log(taskResponse);
          const t = x2jsTasks.xml_str2json(taskResponse.data).tasks;
          self.tasks = t
          self.showMessage('fetched!', 'info')
        }).catch(function (error) {
          if (error.response) {
            // The request was made and the server responded with a status code
            // that falls out of the range of 2xx
            console.log(error.response.data);
            console.log(error.response.status);
            console.log(error.response.headers);
            self.showMessage("ERROR " + error.response.status + ": " + error.response.data, 'error')
          } else if (error.request) {
            // The request was made but no response was received
            // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
            // http.ClientRequest in node.js
            console.log(error.request);
            self.showMessage("ERROR : Failed contacting server", 'error')
          } else {
            // Something happened in setting up the request that triggered an Error
            console.log('Error', error.message);
            self.showMessage("ERROR : Failed setting up server request", 'error')
          }
        });
      }
    }
  })
</script>
