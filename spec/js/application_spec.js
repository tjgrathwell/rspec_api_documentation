describe('Application', function() {
    describe("When changing URL Parameters", function() {
        beforeEach(function(){
            this.wurlForm = $('<form class="wurlForm"></form>');
            this.wrapper = $('<div class="url"></div>');
            this.wrapper.append($('<input class="value url_param" name="post_url_values[orders]" data-key="orders">'));
            this.wrapper.append($('<input id="wurl_request_url" value="/orders/1">'));
            this.wurlForm.append(this.wrapper);

            // For CodeMirror setup
            this.wurlForm.append($('<div class="response body"><textarea>Hello Wurld</textarea></div>'));
            this.wurlForm.append($('<div class="response content_type"><textarea>Hello Wurld</textarea></div>'));
            this.wurl = new Wurl(this.wurlForm);
            $('#jasmine_content').append(this.wurlForm);
        });

        it('sets the new URL in the disabled text field', function(){
            this.urlParamField = this.wurlForm.find("input.value.url_param");
            this.urlParamField.val("5");
            this.urlParamField.trigger('keyup');
            expect(this.wurlForm.find("input#wurl_request_url").val()).toBe("/orders/5");
            expect(this.wurl.url()).toBe('/orders/5')
        });
    });
});