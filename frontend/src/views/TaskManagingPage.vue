<template>
  <v-content><v-container fluid><v-layout row wrap>
    <v-flex xs12>
      <v-layout>
        <v-flex xs6>
          <!-- TODO: fix overflow for very long names -->
          <v-card-text>
            <v-treeview
            :active.sync="active"
            :items="items"
            activatable
            >
          </v-treeview>
        </v-card-text>
      </v-flex>
      <v-divider vertical></v-divider>
      <v-flex xs6>
          <div
            v-if="!selected"
            class="title grey--text text--lighten-1 font-weight-light"
            style="align-self: center;"
          >
            Select a task element
          </div>
          <v-card v-else :key="selected._id">
            <v-card-title primary-title><h2>{{ type2String.get(activeElement.type) }}</h2></v-card-title>
            <v-card-text>
              <v-text-field @focus="$event.target.select()" label="title" required v-model="selected._title"></v-text-field>
              <v-switch
                :disabled="selected._status==='new'"
                v-model="selected._status" :label="selected._status" true-value="open" false-value="locked"></v-switch>
              <v-select
                v-if="['task', 'project', 'projectGroup'].includes(activeElement.type)"
                v-model="selected.member" label="members" chips deletable-chips multiple return-object item-text="_staffmemberId" item-value="_staffmemberId" :items="staff">
              </v-select>
              <v-text-field
                v-if="activeElement.type==='projectGroup'"
                label="customer ID" required v-model="selected._customerId"></v-text-field>
              <v-radio-group
                v-if="activeElement.type==='task'"
                v-model="selected._billableDefault" label="billable default:" row>
                <v-radio label="yes" value="yes"></v-radio>
                <v-radio label="no" value="no"></v-radio>
                <v-radio label="depends" value="depends"></v-radio>
              </v-radio-group>
              <v-btn @click="removeElement(selected)"><v-icon>delete</v-icon></v-btn>
              <v-btn
                v-if="activeElement.type==='projectGroup'"
                @click="addProject(selected)">add project</v-btn>
              <v-btn
                v-if="activeElement.type==='project'"
                @click="addTaskGroup(selected)">add task group</v-btn>
              <v-btn
                v-if="['project', 'taskGroup'].includes(activeElement.type)"
                @click="addTask(selected)">add task</v-btn>
            </v-card-text>

            <v-card-actions>
            </v-card-actions>
          </v-card>
      </v-flex>
    </v-layout>
    <v-btn @click="addProjectGroup">add project group</v-btn>
  </v-flex>

  <v-flex xs12>
    <v-btn color="green" dark @click="submitTasks" raised>submit</v-btn>
    <v-btn @click="loadData">reset</v-btn>
  </v-flex>
  </v-layout></v-container></v-content>
</template>

<script>
  import Vue from 'vue'
  import pageMixin from '@/views/PageMixin.js'
  import {find} from 'deep_find'

  // eslint-disable-next-line
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
        },
        active: [],
        type2String: new Map([['projectGroup', 'project group'], ['project', 'project'], ['taskGroup', 'task group'], ['task', 'task']]),
        // Page scope unique key generator. Uses negative keys to avoid conflicts with ids from back end
        // Back end will generate new keys for all new items
        pskey: -1
      };
    },
    created: function () {
      this.loadData();
    },
    computed: {
      items () {
        if (! this.tasks || ! this.tasks.projectGroup) return []
        return this.getChildren(this.tasks.projectGroup, 'projectGroup')
      },
      selected () {
        if (!this.active.length) return undefined
        const id = this.active[0]
        return find(id, this.tasks, {searchField: '_id'})
      },
      // unfortunately "selected" doesn't own the type of element, so we also compute the active item
      activeElement () {
        if (!this.active.length) return undefined
        const id = this.active[0]
        return find(id, this.items, {searchField: 'id'})
      }

    },
    methods: {
      getChildren: function(elArr, type) {
        if (! elArr || elArr.length==0) return []
        return elArr.map(el => ({
          id: el._id,
          name: el._title,
          type: type,
          children: this.getChildren(el.project, 'project').concat(
            this.getChildren(el.taskGroup, 'taskGroup'),
            this.getChildren(el.task, 'task')
          )
        }))
      },
      addProjectGroup: function() {
        console.log("addProjectGroup")
        const pg = {
          _status: "new",
          _id: this.pskey--,
          _customerId: "",
          _title: "new project group",
        }
        if (! this.tasks.projectGroup) {
          console.log("creating projectGroup array")
          Vue.set(this.tasks, "projectGroup", [])
        }
        this.tasks.projectGroup.push(pg)
      },
      addProject: function(pg) {
        console.log("addProject")
        const p = {
          _status: "new",
          _id: this.pskey--,
          _title: "new project",
        }
        if (! pg.project) {
          console.log("creating project array")
          Vue.set(pg, "project", [])
        }
        pg.project.push(p)
      },
      addTaskGroup: function(p) {
        console.log("addTaskGroup")
        const tg = {
          _status: "new",
          _id: this.pskey--,
          _title: "new task group",
        }
        if (! p.taskGroup) {
          console.log("creating taskGroup array")
          Vue.set(p, "taskGroup", [])
        }
        p.taskGroup.push(tg)
      },
      addTask: function(p) {
        // note: p may be a project or a task group
        console.log("addTask")
        const t = {
          _status: "new",
          _id: this.pskey--,
          _title: "new task",
          _billableDefault: "depends",
        }
        if (! p.task) {
          console.log("creating task array")
          Vue.set(p, "task", [])
        }
        p.task.push(t)
      },
      removeElement: function(el) {
        console.log("removeElement: ", el)
        const id = el._id
        // eslint-disable-next-line
        this.tasks = deepFilter(this.tasks, function(subject, prop) {
          return ! ( subject._id && subject._id === id )
        })

      },
      loadData: function() {
        console.log("loadData")
        const self = this
        self.server.get('../api/tasks/').then(function(taskResponse) {
          console.log("tasks:")
          console.log(taskResponse);
          const t = x2jsTasks.xml_str2json(taskResponse.data).tasks;
          console.log(t)
          self.tasks = t
          self.showMessage('fetched!', 'info')
        }).catch(this.handleHttpError);
      },
      submitTasks: function () {
        console.log("submitTasks")
        // eslint-disable-next-line
        const outjs = deepFilter(this.tasks, function(_, prop) {
          return ! prop.toString().startsWith('$')
        })
        const xmlDocStr = x2jsTasks.json2xml_str({
          tasks: outjs
        })
        console.log(xmlDocStr);
        const self = this
        self.server.post('../api/tasks', xmlDocStr).then(function (response) {
          console.log(response);
          self.showMessage("posted!", 'success');
          self.loadData();
        }).catch(this.handleHttpError);
      }
    }
  })
</script>
