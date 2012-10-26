describe('Application', function() {
    beforeEach(function() {
        this.wurlForm = $('<form class="wurlForm"></form>');
        this.wrapper = $('<div class="url"></div>');
        this.wrapper.append($('<input class="value url_param" name="post_url_values[orders]" data-key="orders">'));
        this.wrapper.append($('<input id="wurl_request_method" value="POST">'));
        this.wrapper.append($('<input id="wurl_request_url" value="/orders/1">'));
        this.wrapper.append($('<div class="headers"><input class="header_pair" id="post_body_values_" name="post_body_values[paid]" data-key="paid" type="text" value="lord"><input disabled=disabled class="header_pair" id="post_body_values_" name="post_body_values[123]" data-key="213" type="text" value="1111"></div>'));
        this.wrapper.append($('<div class="params"><input class="param_pair" id="post_body_values_" name="post_body_values[paid]" data-key="paid" type="text" value="lord"></div>'));
        this.wrapper.append($('<input class="value" id="post_body_values_" name="post_body_values[blah]" data-key="blah" type="text" value="herpington">'));
        this.wrapper.append($('<input class="clear_fields btn" id="clear_fields" type="button" value="Clear">'));
        this.wurlForm.append(this.wrapper);

        // For CodeMirror setup
        this.wurlForm.append($('<div class="response body"><textarea>Hello Wurld</textarea></div>'));
        this.wurlForm.append($('<div class="response content_type"><textarea>Hello Wurld</textarea></div>'));
        this.wurl = new Wurl(this.wurlForm);
        this.urlParamField = this.wurlForm.find("input.value.url_param");
        $('#jasmine_content').append(this.wurlForm);
    });

    describe("When changing URL Parameters", function() {
        it('sets the new URL in the disabled text field', function(){
            this.urlParamField.val("5").trigger('keyup');
            expect(this.wurlForm.find("input#wurl_request_url").val()).toBe("/orders/5");
            expect(this.wurl.url()).toBe('/orders/5')
        });

        describe("when you enter an invalid id", function() {
            it("doesn't update", function() {
                this.urlParamField.val("abc").trigger('keyup');
                expect(this.wurl.url()).toBe('/orders/1')
            });

            it("doesn't update for blanks", function() {
                this.urlParamField.val("").trigger('keyup');
                expect(this.wurl.url()).toBe('/orders/1')
            });
        });
    });

    describe("Getting the data for POST body parameters", function() {
        it("should have the right parameters", function() {
            expect(this.wurl.getData()).toContain("paid=lord&blah=herpington");
        });
    });

    describe("Clear button", function() {
        beforeEach(function() {
            this.beforeCount = this.wurlForm.find("input").size();
            this.wurlForm.find("#clear_fields").click();
        });

        it("doesn't add new fields", function() {
            var newCount = this.wurlForm.find("input").size();
            expect(newCount).toBe(this.beforeCount);
        });

        it("doesn't empty any non-editable fields", function() {
            var inputs = this.wurlForm.find("input:disabled");
            _.each(inputs, function(input) {
                expect($(input).val()).not.toBe("");
            });
        });
    });
});
