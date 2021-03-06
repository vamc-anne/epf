/**
  Same as Ember.isEqual but supports dates
*/
module.exports = function(a, b) {
  if (a && 'function'===typeof a.isEqual) return a.isEqual(b);
  if (a instanceof Date && b instanceof Date) {
    return a.getTime() === b.getTime();
  } 
  return a === b;
}
