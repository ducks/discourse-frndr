import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class DiscoverRoute extends DiscourseRoute {
  async model() {
    return ajax("/frndr/discover");
  }
}
